 %수퍼리자드 pricing
 %미래에셋대우 제29340회 파생결합증권
clear all;

%Parameters
%시간 계산
maturity = convertTo(datetime(2023,10,25), 'excel'); %만기평가일
start_date = convertTo(datetime(2020,10,30), 'excel'); %최초기준가격평가일
tot_date = maturity - start_date;

oneyear = 365; dt = 1/oneyear;

%기본정도
coupon = [0.0255 0.051 0.0765 0.102 0.1275 0.153]; 
dummy = 0.153;
strike_price = [0.92 0.92 0.9 0.9 0.85 0.75] * 100; 
Kib = 0.55*100;
additional_early_exercise = [0.87 0.77] * 100; %추가 자동조기상환조건
face_value = 10000; S0 = 100;
r = 0.0063;%2020-10-30의 CD금리, annualized 
vol = [0.2789 0.2812 0.3346]; %상품설명서에 제시

rho1 = 0.4745; rho2 = 0.3018; rho3 = 0.7065;
corr = [1 rho1 rho2 ; rho1 1 rho3 ; rho2 rho3 1]; %상관계수 행렬
L = chol(corr)'; %촐레스키 분해


%check day 계산
check1= convertTo(datetime(2021,04,27), 'excel') - start_date;
check2= convertTo(datetime(2021,10,26), 'excel') - start_date;
check3= convertTo(datetime(2022,04,26), 'excel') - start_date;
check4= convertTo(datetime(2022,10,25), 'excel') - start_date;
check5= convertTo(datetime(2023,04,25), 'excel') - start_date;
check6 = maturity - start_date;
check_day = [check1, check2, check3, check4, check5, check6];
repay_n = length(coupon); %5번의 조기상환과 만기상환
payment = zeros(1,repay_n); %coupon이 지급되는 경우

for j=1:repay_n
    payment(j) = face_value*(1+coupon(j));
end

SP = zeros(tot_date+1,1); SP(1) = S0;
S1 = zeros(tot_date+1,1); S1(1) = S0;
S2 = zeros(tot_date+1,1); S2(1) = S0;
S3 = zeros(tot_date+1,1); S3(1) = S0;

tot_payoff = 0; 
ns = 100000;

for i = 1:ns
    %Stock Path Generated
    u =randn(3,tot_date);
    e = L*u;
    for j = 1:tot_date
        S1(j+1) = S1(j)*exp((r-vol(1)^2/2)*dt+vol(1)*sqrt(dt)*e(1,j));
        S2(j+1) = S2(j)*exp((r-vol(2)^2/2)*dt+vol(2)*sqrt(dt)*e(2,j));
        S3(j+1) = S3(j)*exp((r-vol(3)^2/2)*dt+vol(3)*sqrt(dt)*e(3,j));
    end 
    
    for i = 1:tot_date
        S_combine = [S1(i+1) S2(i+1) S3(i+1)];
        SP(i+1) = min(S_combine);       
    end
    
    
    Price_at_check_day=SP(check_day+1);
    payoff(1:repay_n) = 0;
    repay_event = 0; %상환 여부 체크
    
    %조기상환평가일에 조기상환조건 체크
    for j = 1:repay_n %1~6경우
        % j번째 상환조건 체크
        if Price_at_check_day(j)>=strike_price(j) %Check day에서의 가격만
            payoff(j) = payment(j);
            repay_event = 1;
            break
        elseif j==1||j==2  % 1-2와 2-2의 경우
            Price_until_check_day = zeros(check_day(j)+1,1); %Check day까지의 가격 전부
            Price_until_check_day = SP(1:check_day(j)+1,1);
            if min(Price_until_check_day) > additional_early_exercise(j)
                payoff(j) = payment(j*2);
                repay_event = 1;
                break
            end
        end
    end
    
    if repay_event == 0
        if min(SP) > Kib %7번째 경우
            payoff(end) = face_value*(1+dummy);
        else %8번째 경우
            payoff(end) = face_value*SP(end)/100;
        end
    end
    %누적합
    tot_payoff = tot_payoff + payoff;
end
tot_payoff = tot_payoff/ns;
%각 시점에 맞게 할인
for j =1:repay_n
    disc_payoff(j) = tot_payoff(j)*exp(-r*check_day(j)/oneyear);
end
ELS_Price = sum(disc_payoff)

