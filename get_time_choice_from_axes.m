function [time, axindex] = get_time_choice_from_axes(fig, axes)

%set(fig, 'Units', 'normalized');
cpnorm = get(fig, 'CurrentPoint');
%figdim = get(fig, 'Position');
%cpnorm = [cpfig(1)/figdim(3) cpfig(2)/figdim(4)];

axindex = 0;

xmargin = 0.03;%figdim(3)/20;

for i=1:length(axes)
    
    axbounds = get(axes(i), 'Position');
    if (cpnorm(1) >= axbounds(1) - xmargin) && ...
        (cpnorm(2) >= axbounds(2)) && ...
        (cpnorm(1) - axbounds(1) <= axbounds(3) + xmargin) && ...
        (cpnorm(2) - axbounds(2) <= axbounds(4))
        axindex = i;
        break;
    end
end

if axindex > 0
    axbounds = get(axes(axindex), 'Position');
    scale = (cpnorm(1) - axbounds(1))/axbounds(3);
    xlim = get(axes(axindex), 'XLim');
    time = xlim(1) + scale*(xlim(2) - xlim(1));
    time = min(max(time, xlim(1)), xlim(2));
else
    time = [];
end
    
