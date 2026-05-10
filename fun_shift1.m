  %%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [seq] = fun_shift1(seq, step, dim)
  % step < 0    -----  Left or up 
  % step > 0    -----  Right or Down
  % Dim =1      -----  Row
  % Dim =2      -----  Col
  [row col]=size(seq);
  
  step = -1*round(step);
  
  if (dim==2) & (abs(step)>=col)
      seq=zeros(row, col);
      return;
  end;
  
  if (dim~=2) & (abs(step) >= row)
        seq=zeros(row, col);
     return;
  end;
  
  
  if step>0
      if dim ==2
          seq= [seq(:, step+1:end) seq(:,end)*ones(row, step)];
      else 
          seq= [seq(step+1:end,:); seq(end,:)*ones(step, col)];
      end;
  end;
  
  if step <0
      if dim ==2
          seq= [seq(:,1)*ones(row, abs(step)) seq(:, 1:end+step) ];
      else 
          seq= [seq(1,:)*ones(abs(step), col); seq(1:end+step,:) ];
      end;
  end;