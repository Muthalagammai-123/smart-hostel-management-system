-- Update Outpass policies to restrict wardens to their assigned outpasses
-- Run this in your Supabase SQL Editor

-- Drop old policies
DROP POLICY IF EXISTS "Warden can view all outpasses." ON public.outpasses;
DROP POLICY IF EXISTS "Warden can update outpasses." ON public.outpasses;

-- New policy: Wardens can ONLY view outpasses assigned to them
CREATE POLICY "Wardens can view assigned outpasses." ON public.outpasses FOR SELECT USING (
    auth.uid() = warden_id OR 
    auth.uid() = student_id OR
    exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
);

-- New policy: Wardens can ONLY update outpasses assigned to them
CREATE POLICY "Wardens can update assigned outpasses." ON public.outpasses FOR UPDATE USING (
    auth.uid() = warden_id OR
    exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
);
