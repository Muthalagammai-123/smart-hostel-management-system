-- Enhanced Outpasses table for student leave requests with additional fields
-- Run this to update the existing table or create a new one

-- Drop existing table if you want to recreate (WARNING: This will delete all data)
-- DROP TABLE IF EXISTS public.outpasses CASCADE;

-- Create enhanced Outpasses table
CREATE TABLE IF NOT EXISTS public.outpasses (
    id text primary key,
    student_id uuid references public.profiles(id) not null,
    
    -- Student Information
    department text not null,
    section text,
    year_of_study text not null,
    student_mobile text not null,
    parent_mobile text not null,
    
    -- Outpass Details
    reason text not null,
    destination text not null,
    from_date timestamp with time zone not null,
    to_date timestamp with time zone not null,
    
    -- Approval Documents (URLs to uploaded PDFs)
    hod_approval_url text,
    class_advisor_approval_url text,
    
    -- Status and Approval
    status text default 'pending', -- pending, approved, rejected
    warden_id uuid references public.profiles(id),
    warden_name text,
    approved_by uuid references public.profiles(id),
    approved_at timestamp with time zone,
    rejection_reason text,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
ALTER TABLE public.outpasses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if recreating
DO $$
BEGIN
    DROP POLICY IF EXISTS "Students can request outpasses." ON public.outpasses;
    DROP POLICY IF EXISTS "Students can view own outpasses." ON public.outpasses;
    DROP POLICY IF EXISTS "Warden can view all outpasses." ON public.outpasses;
    DROP POLICY IF EXISTS "Warden can update outpasses." ON public.outpasses;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Policies

-- 1. Students can request outpasses
CREATE POLICY "Students can request outpasses." ON public.outpasses FOR INSERT WITH CHECK (
    auth.uid() = student_id
);

-- 2. Students can view their OWN outpasses
CREATE POLICY "Students can view own outpasses." ON public.outpasses FOR SELECT USING (
    auth.uid() = student_id
);

-- 3. Wardens can view ALL outpasses
CREATE POLICY "Warden can view all outpasses." ON public.outpasses FOR SELECT USING (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'warden')
);

-- 4. Wardens can update outpass status
CREATE POLICY "Warden can update outpasses." ON public.outpasses FOR UPDATE USING (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'warden')
);

-- If updating existing table, add new columns
DO $$
BEGIN
    -- Add new columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'department') THEN
        ALTER TABLE public.outpasses ADD COLUMN department text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'section') THEN
        ALTER TABLE public.outpasses ADD COLUMN section text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'year_of_study') THEN
        ALTER TABLE public.outpasses ADD COLUMN year_of_study text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'student_mobile') THEN
        ALTER TABLE public.outpasses ADD COLUMN student_mobile text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'parent_mobile') THEN
        ALTER TABLE public.outpasses ADD COLUMN parent_mobile text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'hod_approval_url') THEN
        ALTER TABLE public.outpasses ADD COLUMN hod_approval_url text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'class_advisor_approval_url') THEN
        ALTER TABLE public.outpasses ADD COLUMN class_advisor_approval_url text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'warden_id') THEN
        ALTER TABLE public.outpasses ADD COLUMN warden_id uuid REFERENCES public.profiles(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'outpasses' AND column_name = 'warden_name') THEN
        ALTER TABLE public.outpasses ADD COLUMN warden_name text;
    END IF;
END $$;
