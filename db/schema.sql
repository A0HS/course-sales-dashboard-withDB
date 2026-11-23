-- 전국 대리점 현황의 대리점 시트를 저장하는 테이블
CREATE TABLE IF NOT EXISTS dealers (
    dealer_code    VARCHAR(20)  PRIMARY KEY,
    dealer_name    VARCHAR(100) NOT NULL,
    region         VARCHAR(30)  NOT NULL,
    province       VARCHAR(50)  NOT NULL,
    district       VARCHAR(50)  NOT NULL,
    representative VARCHAR(50)  NOT NULL,
    phone          VARCHAR(30)  NOT NULL,
    opened_on      DATE         NOT NULL,
    grade          VARCHAR(20)  NOT NULL CHECK (grade IN ('일반', '실버', '골드')),
    status         VARCHAR(20)  NOT NULL CHECK (status IN ('운영', '휴업', '계약종료')),
    sales_manager  VARCHAR(50)  NOT NULL,
    annual_sales   BIGINT       NOT NULL CHECK (annual_sales >= 0)
);

CREATE INDEX IF NOT EXISTS dealers_province_idx ON dealers (province);

-- Neon Data API: 로그인 없이 공개 화면에서 읽을 수 있는 컬럼만 노출
ALTER TABLE public.dealers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.dealers FROM anonymous;
GRANT USAGE ON SCHEMA public TO anonymous;
GRANT SELECT (dealer_code, dealer_name, region, province, district, opened_on, grade, status, annual_sales)
    ON public.dealers TO anonymous;
DROP POLICY IF EXISTS public_dealers_read ON public.dealers;
CREATE POLICY public_dealers_read
    ON public.dealers
    FOR SELECT
    TO anonymous
    USING (true);

-- 관리자 허용 목록: Neon Auth 사용자 ID를 여기에 등록한 계정만 쓰기 가능
CREATE TABLE IF NOT EXISTS public.dealer_admins (
    user_id    TEXT PRIMARY KEY,
    email      TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
REVOKE ALL ON public.dealer_admins FROM PUBLIC, anonymous, authenticated;
ALTER TABLE public.dealer_admins ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_dealer_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.dealer_admins
        WHERE user_id = auth.user_id()
    );
$$;
REVOKE ALL ON FUNCTION public.is_dealer_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_dealer_admin() TO authenticated;

-- 로그인 사용자는 공개 목록을 읽을 수 있지만, 쓰기는 관리자 허용 목록으로 제한
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT (dealer_code, dealer_name, region, province, district, opened_on, grade, status, annual_sales)
    ON public.dealers TO authenticated;
GRANT INSERT (dealer_code, dealer_name, region, province, district, representative, phone, opened_on, grade, status, sales_manager, annual_sales)
    ON public.dealers TO authenticated;
GRANT UPDATE (dealer_code, dealer_name, region, province, district, representative, phone, opened_on, grade, status, sales_manager, annual_sales)
    ON public.dealers TO authenticated;
DROP POLICY IF EXISTS authenticated_dealers_read ON public.dealers;
CREATE POLICY authenticated_dealers_read
    ON public.dealers
    FOR SELECT
    TO authenticated
    USING (true);
DROP POLICY IF EXISTS admin_dealers_insert ON public.dealers;
CREATE POLICY admin_dealers_insert
    ON public.dealers
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_dealer_admin());
DROP POLICY IF EXISTS admin_dealers_update ON public.dealers;
CREATE POLICY admin_dealers_update
    ON public.dealers
    FOR UPDATE
    TO authenticated
    USING (public.is_dealer_admin())
    WITH CHECK (public.is_dealer_admin());
