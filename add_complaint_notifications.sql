-- Trigger to notify students when their complaint is updated by warden/management
-- This should be run AFTER creating the complaints table

-- Create the trigger function
CREATE OR REPLACE FUNCTION notify_complaint_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Only send notification if status changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.notifications (
            id,
            user_id,
            type,
            title,
            message,
            created_at
        ) VALUES (
            gen_random_uuid()::text,
            NEW.student_id,
            'complaint',
            'Complaint Status Updated',
            'Your complaint "' || NEW.title || '" has been updated to: ' || NEW.status,
            now()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_complaint_update ON public.complaints;
CREATE TRIGGER on_complaint_update
    AFTER UPDATE ON public.complaints
    FOR EACH ROW
    EXECUTE FUNCTION notify_complaint_update();
