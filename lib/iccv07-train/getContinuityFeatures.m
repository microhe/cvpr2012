function [tx, cf] = getContinuityFeatures(X, bndinfo, c1, nextc, pC, type)

nextc = reshape(nextc, [1 numel(nextc)]);
nc2 = numel(nextc);

tx = zeros(nc2, 29); % features: continuity + pContour of same type
  
ne = bndinfo.ne;

% get relative angles between c1 and contours in c2
theta = bndinfo.edges.thetaDirected(mod([c1 nextc]-1, ne)+1) / pi * 180;
theta([c1 nextc]>ne) = theta([c1 nextc]>ne) + 180;
theta(theta > 180) = (theta(theta>180)-360);
relAngle = theta(2:end)-theta(1);
relAngle(relAngle > 180) = relAngle(relAngle > 180)-360;
relAngle(relAngle <= -180) = relAngle(relAngle <= -180)+360;
       
for tc = 1:nc2
    
    c2 = nextc(tc);
    
%     tx(tc, :) = [relAngle(tc)       abs(relAngle(tc)) ...
%                  pC(c1, type+1)     pC(c2, type+1) ...
%                  pC(c1, 1)        pC(c2, 1) ...
%                  X(c2, 16)          type ...
%                  X(c2, [1:15 17:end]) ]; 

    if c2 <= ne

        tx(tc, 1:25) = [relAngle(tc)       abs(relAngle(tc)) ...
                        pC(c1, 1:2)        pC(c2, 1:2) ...
                        X(c2, 16)          X(c2, [1:15 17:end]) ];
    else  % need to reflect geometry features
        tc2 = c2 - ne;
        tx(tc, 1:25) = [relAngle(tc)       abs(relAngle(tc)) ...
                        pC(c1, 1:2)        pC(c2, 1:2) ...
                        X(tc2, 16)                          ...
                        X(tc2, 11:15)      -X(tc2, 6:10)  ...
                        X(tc2, 1:5)        X(tc2, 17:end)];       
    end   
end

nf = 25;
%cf = [8 24];
cf = [23];

if 1

if nc2 > 1   
    
    % changing to relative features
    tx(:, nf+1) = tx(:, 6) / sum(tx(:, 6)); % normalized confidence
    
    [sorta, saind] = sort(tx(:, 2), 'ascend');  % abs relative angle 
    [sortp, spind] = sort(tx(:, 6), 'descend'); % % p(contour)
    [sortp2, spind2] = sort(tx(:, 7), 'descend');  % pB (original)
    for tc = 1:nc2

        if tc==spind(1), tx(tc, nf+2) = sortp(tc)-sortp(2); % positive margin
        else tx(tc, nf+2) = sortp(tc)-sortp(1); % negative margin 
        end

        if tc==saind(1), tx(tc, nf+3) = sorta(tc)-sorta(2); % positive margin
        else tx(tc, nf+3) = sorta(tc)-sorta(1); % negative margin 
        end 

        if tc==spind2(1), tx(tc, nf+4) = sortp2(tc)-sortp2(2); % positive margin
        else tx(tc, nf+4) = sortp2(tc)-sortp2(1); % negative margin 
        end        
        
    end    
    
elseif nc2==1
    
    tx(1, nf+(1:4)) = [1 0 0 1];
end

%cf = [];
end