-- Update complaints table to allow selecting specific warden and admin
-- Run this in your Supabase SQL Editor

ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS warden_id uuid REFERENCES public.profiles(id);
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS admin_id uuid REFERENCES public.profiles(id);

-- Update RLS policies to restrict visibility
-- A warden should only see complaints where they are the specific warden
-- An admin should only see complaints where they are the specific admin

-- Remove old "Warden can view all complaints" policy
DROP POLICY IF EXISTS "Warden can view all complaints." ON public.complaints;
DROP POLICY IF EXISTS "Warden can update complaints." ON public.complaints;

-- New targeted policies
CREATE POLICY "Wardens can view assigned complaints." ON public.complaints FOR SELECT USING (
    auth.uid() = warden_id OR 
    auth.uid() = student_id
);

CREATE POLICY "Admins can view assigned complaints." ON public.complaints FOR SELECT USING (
    auth.uid() = admin_id OR 
    (exists (select 1 from public.profiles where id = auth.uid() and role = 'management' and admin_id IS NULL)) OR -- Handle cases where it was legacy
    auth.uid() = student_id
);

-- For simplicity in management role (if a management user is not explicitly assigned, they might still need to see all? 
-- The user said "only to specific student it should send", and "selecting warden and admin". 
-- So let's make it strict.)

CREATE POLICY "Wardens can update assigned complaints." ON public.complaints FOR UPDATE USING (
    auth.uid() = warden_id
);

CREATE POLICY "Admins can update assigned complaints." ON public.complaints FOR UPDATE USING (
    auth.uid() = admin_id
);
