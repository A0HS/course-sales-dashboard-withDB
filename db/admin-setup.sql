-- 1) Neon Console > Auth > Users에서 관리자를 만들거나,
--    CLI로 사용자를 만듭니다:
--    neon neon-auth user create --project-id withered-recipe-79599589
--      --branch br-little-pine-az4dddok --email admin@example.com --name 관리자
-- 2) 해당 계정의 이메일/비밀번호 설정 또는 초대 절차를 완료합니다.
-- 3) 아래 이메일을 실제 관리자 이메일로 바꿔 실행합니다.
--    (Neon SQL Editor 또는 neon psql에서 실행)

INSERT INTO public.dealer_admins (user_id, email)
SELECT id, email
FROM neon_auth.user
WHERE email = 'admin@example.com'
ON CONFLICT (user_id) DO NOTHING;

-- 등록 확인
SELECT user_id, email, created_at
FROM public.dealer_admins
ORDER BY created_at DESC;
