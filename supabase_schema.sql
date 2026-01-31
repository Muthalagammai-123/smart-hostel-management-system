-- IMPORTANT: This script will reset your database. 
-- If you want to keep existing data, use the MIGRATION script below instead.

-- CLEAN SLATE RESET (Optional: Uncomment to reset everything)
-- DROP TABLE IF EXISTS public.profiles CASCADE;
-- DROP TABLE IF EXISTS public.issues CASCADE;
-- DROP TABLE IF EXISTS public.announcements CASCADE;
-- DROP TABLE IF EXISTS public.lost_found CASCADE;
-- DROP TABLE IF EXISTS public.notifications CASCADE;

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text,
  role text check (role in ('student', 'management', 'maintenance', 'warden')),
  department text,
  hostel text,
  building text,
  floor text,
  room text,
  avatar_url text,
  availability text default 'available',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles (Using DO blocks to avoid "already exists" errors)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public profiles are viewable by everyone.') THEN
        CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own profile.') THEN
        CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile.') THEN
        CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- 2. ISSUES TABLE
CREATE TABLE IF NOT EXISTS public.issues (
  id text primary key,
  title text not null,
  description text,
  category text not null,
  priority text not null,
  status text default 'pending' not null,
  location text not null,
  room_number text,
  student_id uuid references public.profiles(id) not null,
  assigned_to uuid references public.profiles(id),
  resolved_at timestamp with time zone,
  work_notes text[] default '{}',
  is_public boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add is_public column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'issues' AND column_name = 'is_public') THEN
        ALTER TABLE public.issues ADD COLUMN is_public boolean default false;
    END IF;
END $$;

ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Individuals can view their own issues.') THEN
        CREATE POLICY "Individuals can view their own issues." ON public.issues FOR SELECT USING (auth.uid() = student_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Staff can view assigned issues.') THEN
        CREATE POLICY "Staff can view assigned issues." ON public.issues FOR SELECT USING (auth.uid() = assigned_to);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can view all issues.') THEN
        CREATE POLICY "Management can view all issues." ON public.issues FOR SELECT USING (
          exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Students can report issues.') THEN
        CREATE POLICY "Students can report issues." ON public.issues FOR INSERT WITH CHECK (auth.uid() = student_id);
    END IF;
END $$;

-- 3. ANNOUNCEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.announcements (
  id text primary key,
  title text not null,
  content text not null,
  priority text default 'medium',
  target text default 'all',
  created_by uuid references public.profiles(id) not null,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Policies for announcements
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Everyone can view announcements.') THEN
        CREATE POLICY "Everyone can view announcements." ON public.announcements FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can create announcements.') THEN
        CREATE POLICY "Management can create announcements." ON public.announcements FOR INSERT WITH CHECK (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can update announcements.') THEN
        CREATE POLICY "Management can update announcements." ON public.announcements FOR UPDATE USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can delete announcements.') THEN
        CREATE POLICY "Management can delete announcements." ON public.announcements FOR DELETE USING (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
END $$;

-- 4. LOST & FOUND TABLE
CREATE TABLE IF NOT EXISTS public.lost_found (
  id text primary key,
  title text not null,
  description text,
  category text,
  location text,
  status text default 'lost',
  reported_by uuid references public.profiles(id) not null,
  reported_by_name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.lost_found ENABLE ROW LEVEL SECURITY;

-- 5. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id text primary key,
  user_id uuid references public.profiles(id) not null,
  title text not null,
  message text not null,
  type text,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policies for notifications
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own notifications.') THEN
        CREATE POLICY "Users can view their own notifications." ON public.notifications FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own notifications.') THEN
        CREATE POLICY "Users can update their own notifications." ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Management can insert notifications.') THEN
        CREATE POLICY "Management can insert notifications." ON public.notifications FOR INSERT WITH CHECK (
            exists (select 1 from public.profiles where id = auth.uid() and role = 'management')
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'System can insert notifications.') THEN
        CREATE POLICY "System can insert notifications." ON public.notifications FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- TRIGGER FOR AUTH.USERS TO PROFILES
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, department, hostel, building, floor, room)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'role', 'student'),
    new.raw_user_meta_data->>'department',
    new.raw_user_meta_data->>'hostel',
    COALESCE(new.raw_user_meta_data->>'block', new.raw_user_meta_data->>'building'),
    new.raw_user_meta_data->>'floor',
    new.raw_user_meta_data->>'room'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists to avoid errors on re-run
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==========================================
-- MIGRATION: RUN THIS IF YOU ALREADY HAVE TABLES
-- ==========================================
-- ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
-- ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('student', 'management', 'maintenance', 'warden'));
