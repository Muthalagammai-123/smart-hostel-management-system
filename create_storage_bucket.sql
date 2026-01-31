-- Create storage bucket for outpass approval documents
-- Run this in Supabase SQL Editor

-- Insert the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public)
VALUES ('outpass-approvals', 'outpass-approvals', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to upload files
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Allow authenticated uploads to outpass-approvals'
    ) THEN
        CREATE POLICY "Allow authenticated uploads to outpass-approvals"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'outpass-approvals');
    END IF;
END $$;

-- Policy: Allow public to view files (since bucket is public)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Allow public to view outpass-approvals'
    ) THEN
        CREATE POLICY "Allow public to view outpass-approvals"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'outpass-approvals');
    END IF;
END $$;

-- Policy: Allow users to update their own files
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Allow users to update own files in outpass-approvals'
    ) THEN
        CREATE POLICY "Allow users to update own files in outpass-approvals"
        ON storage.objects FOR UPDATE
        TO authenticated
        USING (bucket_id = 'outpass-approvals' AND auth.uid()::text = owner);
    END IF;
END $$;

-- Policy: Allow users to delete their own files
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Allow users to delete own files in outpass-approvals'
    ) THEN
        CREATE POLICY "Allow users to delete own files in outpass-approvals"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (bucket_id = 'outpass-approvals' AND auth.uid()::text = owner);
    END IF;
END $$;
