-- Refined Targeted Complaint Policies
-- Run this in your Supabase SQL Editor

-- 1. Students can view only their own complaints
DROP POLICY IF EXISTS "Students can view own complaints." ON public.complaints;
CREATE POLICY "Students can view own complaints." ON public.complaints 
FOR SELECT USING (auth.uid() = student_id);

-- 2. Wardens can view ONLY if they are assigned as the warden for that complaint
DROP POLICY IF EXISTS "Wardens can view assigned complaints." ON public.complaints;
CREATE POLICY "Wardens can view assigned complaints." ON public.complaints 
FOR SELECT USING (auth.uid() = warden_id);

-- 3. Admins can view ONLY if they are assigned as the admin for that complaint
DROP POLICY IF EXISTS "Admins can view assigned complaints." ON public.complaints;
CREATE POLICY "Admins can view assigned complaints." ON public.complaints 
FOR SELECT USING (auth.uid() = admin_id);

-- 4. Enable updates for assigned staff
DROP POLICY IF EXISTS "Wardens can update assigned complaints." ON public.complaints;
CREATE POLICY "Wardens can update assigned complaints." ON public.complaints 
FOR UPDATE USING (auth.uid() = warden_id);

DROP POLICY IF EXISTS "Admins can update assigned complaints." ON public.complaints;
CREATE POLICY "Admins can update assigned complaints." ON public.complaints 
FOR UPDATE USING (auth.uid() = admin_id);

-- Allow system/management to insert (students insert their own)
DROP POLICY IF EXISTS "Students can submit complaints." ON public.complaints;
CREATE POLICY "Students can submit complaints." ON public.complaints 
FOR INSERT WITH CHECK (auth.uid() = student_id);
