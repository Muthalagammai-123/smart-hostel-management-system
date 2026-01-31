-- Add UPDATE policies for issues table
-- This fixes the issue where "Save Changes" appears to work but nothing happens in the database.

-- 1. Management can update any issue
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can update all issues.') THEN
        CREATE POLICY "Management can update all issues." ON public.issues FOR UPDATE USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
END $$;

-- 2. Maintenance staff can update issues assigned to them
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Staff can update assigned issues.') THEN
        CREATE POLICY "Staff can update assigned issues." ON public.issues FOR UPDATE USING (
            auth.uid() = assigned_to
        );
    END IF;
END $$;
