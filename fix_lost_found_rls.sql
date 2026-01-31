-- Enable permissions for Lost & Found
-- Fixes "new row violates row-level security policy" error

-- 1. Everyone can view lost/found items
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Everyone can view lost found items.') THEN
        CREATE POLICY "Everyone can view lost found items." ON public.lost_found FOR SELECT USING (true);
    END IF;
END $$;

-- 2. Authenticated users can report items (INSERT)
-- We check that the user is inserting their own ID as 'reported_by'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can report lost found items.') THEN
        CREATE POLICY "Users can report lost found items." ON public.lost_found FOR INSERT WITH CHECK (
            auth.uid() = reported_by
        );
    END IF;
END $$;

-- 3. Users can update their own reported items (e.g., mark as found/returned)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own reported items.') THEN
        CREATE POLICY "Users can update their own reported items." ON public.lost_found FOR UPDATE USING (
            auth.uid() = reported_by
        );
    END IF;
END $$;

-- 4. Management can manage all items
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can manage all lost found items.') THEN
        CREATE POLICY "Management can manage all lost found items." ON public.lost_found FOR ALL USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
END $$;
