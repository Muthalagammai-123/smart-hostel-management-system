-- Clean Seeding Script for Attendance Configuration
-- This script sets up the necessary floor rules for wardens without creating invalid user profiles

DO $$
DECLARE
    warden_rec RECORD;
BEGIN
    -- 1. Create attendance config for every existing Warden's floor
    -- This is the critical prerequisite for the attendance system to work
    FOR warden_rec IN (SELECT * FROM public.profiles WHERE role = 'warden') LOOP
        
        INSERT INTO public.attendance_config (
            hostel,
            building,
            floor,
            qr_secret_daily,
            lat,
            lng,
            radius_meters,
            check_in_start,
            check_in_end
        ) VALUES (
            warden_rec.hostel,
            warden_rec.building,
            warden_rec.floor,
            'SECRET_' || UPPER(LEFT(warden_rec.id::text, 4)), 
            12.9716, -- Default example Latitude
            77.5946, -- Default example Longitude
            150,     -- 150 meter radius
            '18:00', -- 6:00 PM
            '22:30'  -- 10:30 PM
        ) ON CONFLICT (hostel, building, floor) 
        DO UPDATE SET 
            qr_secret_daily = EXCLUDED.qr_secret_daily,
            check_in_start = EXCLUDED.check_in_start,
            check_in_end = EXCLUDED.check_in_end;
            
    END LOOP;

    -- 2. Create a global default config for 'Main' hostel if needed
    INSERT INTO public.attendance_config (
        hostel, building, floor, qr_secret_daily, lat, lng, radius_meters, check_in_start, check_in_end
    ) VALUES (
        'Main', 'Block A', '1', 'DEMO123', 12.9716, 77.5946, 150, '00:00', '23:59'
    ) ON CONFLICT DO NOTHING;

END $$;
