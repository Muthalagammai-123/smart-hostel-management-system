-- Create Outpasses table for student leave requests
CREATE TABLE IF NOT EXISTS public.outpasses (
    id text primary key,
    student_id uuid references public.profiles(id) not null,
    reason text not null,
    destination text not null,
    from_date timestamp with time zone not null,
    to_date timestamp with time zone not null,
    status text default 'pending', -- pending, approved, rejected
    approved_by uuid references public.profiles(id),
    approved_at timestamp with time zone,
    rejection_reason text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
ALTER TABLE public.outpasses ENABLE ROW LEVEL SECURITY;

-- Policies

-- 1. Students can request outpasses
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Students can request outpasses.') THEN
        CREATE POLICY "Students can request outpasses." ON public.outpasses FOR INSERT WITH CHECK (
            auth.uid() = student_id
        );
    END IF;
END $$;

-- 2. Students can view their OWN outpasses
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Students can view own outpasses.') THEN
        CREATE POLICY "Students can view own outpasses." ON public.outpasses FOR SELECT USING (
            auth.uid() = student_id
        );
    END IF;
END $$;

-- 3. Wardens can view ALL outpasses
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Warden can view all outpasses.') THEN
        CREATE POLICY "Warden can view all outpasses." ON public.outpasses FOR SELECT USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'warden')
        );
    END IF;
END $$;

-- 4. Wardens can update outpass status
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Warden can update outpasses.') THEN
        CREATE POLICY "Warden can update outpasses." ON public.outpasses FOR UPDATE USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'warden')
        );
    END IF;
END $$;
