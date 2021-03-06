function [ fselect, PSDselect, L ,P ] = get_psd_features( f, PSD, tH )
%
sPSD = f>=tH(1) & f<=tH(2); %selectPSD
fselect = f(sPSD);
PSDselect = PSD(sPSD);

if length(PSDselect)>1
    [P1,L1] = max(PSDselect);
%     [P1,L1] = findpeaks(PSDselect,'SortStr','descend');
else
    P1=[];
    L1=[];
end
if ~isempty(P1)
    L = fselect(L1(1));
    P = P1(1);
else
    L = 0;
    P = 0;
end

end

