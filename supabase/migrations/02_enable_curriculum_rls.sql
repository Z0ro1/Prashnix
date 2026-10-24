-- Migration: Enable full CRUD permissions on curriculum tables for admin dashboard
-- Table: questions, units, nodes, lessons

DO $$ 
BEGIN
  -- Questions
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Enable insert for all users') THEN
    CREATE POLICY "Enable insert for all users" ON public.questions FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Enable update for all users') THEN
    CREATE POLICY "Enable update for all users" ON public.questions FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Enable delete for all users') THEN
    CREATE POLICY "Enable delete for all users" ON public.questions FOR DELETE USING (true);
  END IF;

  -- Units
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'units' AND policyname = 'Enable insert for all users') THEN
    CREATE POLICY "Enable insert for all users" ON public.units FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'units' AND policyname = 'Enable update for all users') THEN
    CREATE POLICY "Enable update for all users" ON public.units FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'units' AND policyname = 'Enable delete for all users') THEN
    CREATE POLICY "Enable delete for all users" ON public.units FOR DELETE USING (true);
  END IF;

  -- Nodes
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nodes' AND policyname = 'Enable insert for all users') THEN
    CREATE POLICY "Enable insert for all users" ON public.nodes FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nodes' AND policyname = 'Enable update for all users') THEN
    CREATE POLICY "Enable update for all users" ON public.nodes FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nodes' AND policyname = 'Enable delete for all users') THEN
    CREATE POLICY "Enable delete for all users" ON public.nodes FOR DELETE USING (true);
  END IF;

  -- Lessons
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Enable insert for all users') THEN
    CREATE POLICY "Enable insert for all users" ON public.lessons FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Enable update for all users') THEN
    CREATE POLICY "Enable update for all users" ON public.lessons FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Enable delete for all users') THEN
    CREATE POLICY "Enable delete for all users" ON public.lessons FOR DELETE USING (true);
  END IF;
END $$;
