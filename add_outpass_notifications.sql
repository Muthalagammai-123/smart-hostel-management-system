-- Trigger to notify students when their outpass status is updated by warden
-- This should be run AFTER creating the outpasses table

-- Create the trigger function
CREATE OR REPLACE FUNCTION notify_outpass_update()
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
            'outpass',
            'Outpass Request ' || CASE 
                WHEN NEW.status = 'approved' THEN 'Approved'
                WHEN NEW.status = 'rejected' THEN 'Rejected'
                ELSE 'Updated'
            END,
            CASE 
                WHEN NEW.status = 'approved' THEN 'Your outpass request to ' || NEW.destination || ' has been approved!'
                WHEN NEW.status = 'rejected' THEN 'Your outpass request to ' || NEW.destination || ' has been rejected. Reason: ' || COALESCE(NEW.rejection_reason, 'Not specified')
                ELSE 'Your outpass status has been updated to: ' || NEW.status
            END,
            now()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_outpass_update ON public.outpasses;
CREATE TRIGGER on_outpass_update
    AFTER UPDATE ON public.outpasses
    FOR EACH ROW
    EXECUTE FUNCTION notify_outpass_update();
