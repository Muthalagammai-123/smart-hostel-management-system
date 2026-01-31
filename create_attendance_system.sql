-- QR-Based Attendance System Schema

-- 1. Create the attendance table
CREATE TABLE IF NOT EXISTS public.attendance (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id uuid REFERENCES public.profiles(id) NOT NULL,
    check_in_time timestamp with time zone DEFAULT now(),
    date date DEFAULT CURRENT_DATE NOT NULL,
    status text CHECK (status IN ('present', 'absent', 'late')) DEFAULT 'present',
    gps_lat numeric,
    gps_long numeric,
    is_verified boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(student_id, date)
);

-- 2. Add Attendance Configuration (per Floor/Wing)
CREATE TABLE IF NOT EXISTS public.attendance_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    hostel text NOT NULL,
    building text NOT NULL,
    floor text NOT NULL,
    qr_secret_daily text NOT NULL,
    lat numeric NOT NULL,
    lng numeric NOT NULL,
    radius_meters integer DEFAULT 100,
    check_in_start time DEFAULT '18:00:00',
    check_in_end time DEFAULT '22:30:00',
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(hostel, building, floor)
);

-- Enable RLS
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_config ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies for Attendance
-- Students can only see their own attendance
CREATE POLICY "Students can view own attendance." ON public.attendance
    FOR SELECT USING (auth.uid() = student_id);

-- Wardens can view attendance of students in their floor
CREATE POLICY "Wardens can view floor attendance." ON public.attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p_warden
            JOIN public.profiles p_student ON p_student.id = public.attendance.student_id
            WHERE p_warden.id = auth.uid() 
            AND p_warden.role = 'warden'
            AND p_warden.hostel = p_student.hostel
            AND p_warden.building = p_student.building
            AND p_warden.floor = p_student.floor
        )
        OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'management')
    );

-- Students can insert their own attendance (with verification logic in app/functions)
CREATE POLICY "Students can mark own attendance." ON public.attendance
    FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Wardens can update attendance for corrections
CREATE POLICY "Wardens can update student attendance." ON public.attendance
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles p_warden
            JOIN public.profiles p_student ON p_student.id = public.attendance.student_id
            WHERE p_warden.id = auth.uid() 
            AND p_warden.role = 'warden'
            AND p_warden.hostel = p_student.hostel
            AND p_warden.building = p_student.building
            AND p_warden.floor = p_student.floor
        )
        OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'management')
    );

-- 4. RLS Policies for Attendance Config
-- Config is viewable by all (to allow students to verify QR secret and location)
-- However, we only need students to fetch it for validation.
CREATE POLICY "Anyone can view attendance config." ON public.attendance_config
    FOR SELECT USING (true);

-- Only management/wardens can update config
CREATE POLICY "Staff can update attendance config." ON public.attendance_config
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('warden', 'management'))
    );
