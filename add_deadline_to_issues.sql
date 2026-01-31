-- Add deadline column to issues table
ALTER TABLE public.issues 
ADD COLUMN IF NOT EXISTS deadline TIMESTAMPTZ;

-- Add comment
COMMENT ON COLUMN public.issues.deadline IS 'Deadline for completing the issue';

-- Create index for faster queries on deadline
CREATE INDEX IF NOT EXISTS idx_issues_deadline ON public.issues(deadline);

-- Create a function to check if an issue is overdue
CREATE OR REPLACE FUNCTION is_issue_overdue(issue_deadline TIMESTAMPTZ, issue_status TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- An issue is overdue if:
    -- 1. It has a deadline
    -- 2. The deadline has passed
    -- 3. The status is not 'resolved' or 'cannot-resolve'
    IF issue_deadline IS NULL THEN
        RETURN FALSE;
    END IF;
    
    IF issue_status IN ('resolved', 'cannot-resolve') THEN
        RETURN FALSE;
    END IF;
    
    RETURN NOW() > issue_deadline;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create a view for active issues count per staff
CREATE OR REPLACE VIEW staff_active_issues_count AS
SELECT 
    assigned_to,
    COUNT(*) as active_count
FROM public.issues
WHERE status NOT IN ('resolved', 'cannot-resolve')
    AND assigned_to IS NOT NULL
GROUP BY assigned_to;

COMMENT ON VIEW staff_active_issues_count IS 'Count of active (non-resolved) issues per maintenance staff';
