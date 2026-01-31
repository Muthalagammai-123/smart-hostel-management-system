-- Create Complaints table for sensitive/anonymous issues
CREATE TABLE IF NOT EXISTS public.complaints (
    id text primary key,
    title text not null,
    description text not null,
    category text default 'general',
    is_anonymous boolean default false,
    status text default 'pending', -- pending, investigating, resolved, dismissed
    student_id uuid references public.profiles(id) not null,
    resolution_notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- Policies

-- 1. Students can submit complaints
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Students can submit complaints.') THEN
        CREATE POLICY "Students can submit complaints." ON public.complaints FOR INSERT WITH CHECK (
            auth.uid() = student_id
        );
    END IF;
END $$;

-- 2. Students can view their OWN complaints only
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Students can view own complaints.') THEN
        CREATE POLICY "Students can view own complaints." ON public.complaints FOR SELECT USING (
            auth.uid() = student_id
        );
    END IF;
END $$;

-- 3. Management and Wardens can view ALL complaints
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Warden can view all complaints.') THEN
        CREATE POLICY "Warden can view all complaints." ON public.complaints FOR SELECT USING (
            exists (select 1 from public.profiles where id = auth.uid() and role in ('management', 'warden'))
        );
    END IF;
END $$;

-- 4. Management and Wardens can update status/notes
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Warden can update complaints.') THEN
        CREATE POLICY "Warden can update complaints." ON public.complaints FOR UPDATE USING (
            exists (select 1 from public.profiles where id = auth.uid() and role in ('management', 'warden'))
        );
    END IF;
END $$;
