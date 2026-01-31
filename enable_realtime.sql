-- Enable realtime for notifications, outpasses, and complaints
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.outpasses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
