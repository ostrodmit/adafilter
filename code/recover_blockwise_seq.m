function x = recover_blockwise_seq(y,T,control,verb,neighb)
% works both with 1d and 2d signals
% parallelized
N = size(y);
if iscolumn(y), dim = 1; else dim = 2; end
n = 2*T; % block size, at each block L+1=T and n=L+T+1, hence n=2*T
% for pointwise mode replace to n = 4T
if min(N(1:dim)) < n
    error('Size must be at least 2*W');
end
x = zeros(N(1),N(2));
% dimensions of the grid, each block is processed independently
m = ones(2,1);
for ax = 1:dim
    m(ax) = floor(N(ax)/n);
end
blockRec = zeros(m(1)*m(2),n,n^(dim-1));
if verb
    blocksToProcess = (m(1)+(N(1)~=m(1)*n))*(m(2)+(N(2)~=m(2)*n))^(dim-1);
    disp(['Blockwise mode. W = ' num2str(T) ...
          '. Blocks to process: ' num2str(blocksToProcess)]);
    wb = waitbar(0,'Processing...','WindowStyle','modal');
end
%%%%%%%%%%%%%%%%%%%% process blocks of the main grid %%%%%%%%%%%%%%%%%%%%%%
initial = [];
for blockIdx = 1:m(1)*m(2)
    % get 2-dimensional block index
    i1 = idivide(blockIdx-1,uint32(m(2)))+1;
    i2 = mod(blockIdx-1,m(2))+1;
    % get 2-dimensional pixel indices
    t1=(i1-1)*n+1:i1*n;
    if dim == 1
        t2 = 1;
    else
        t2 = (i2-1)*n+1:i2*n;
    end
    if ~neighb,
        initial = [];
    end
    [blockRec(blockIdx,:,:),initial]...
        = recover_block(y(t1,t2),0,T,control,initial);
    if verb, waitbar(blockIdx/blocksToProcess); end
end
for blockIdx = 1:m(1)*m(2)
    % get 2-dimensional block index
    i1 = idivide(blockIdx-1,uint32(m(2)))+1;
    i2 = mod(blockIdx-1,m(2))+1;
    % get 2-dimensional pixel indices
    t1=(i1-1)*n+1:i1*n;
    if dim == 1
        t2 = 1;
    else
        t2 = (i2-1)*n+1:i2*n;
    end
    x(t1,t2) = blockRec(blockIdx,:,:);
end
%%%%%%%%%%%%%%%%%% process blocks at the bottom if any %%%%%%%%%%%%%%%%%%%%
initial = [];
if N(1) ~= m(1)*n
    for i2 = 1:m(2)
        if ~neighb,
            initial = [];
        end
        t1 = N(1)-n+1:N(1);
        if dim == 1
            [x(t1),initial] = recover_block(y(t1),0,T,control,initial);
        else
            t2 = (i2-1)*n+1:i2*n;
            [x(t1,t2),initial] = recover_block(y(t1,t2),0,T,control,initial);
        end
        if verb, waitbar((m(1)*m(2)+i2)/blocksToProcess); end
    end
end
%%%%%%%%%%%%%%%%%% process blocks on the right if any %%%%%%%%%%%%%%%%%%%%%
initial = [];
if dim == 2 && N(2) ~= m(2)*n
    for i1 = 1:m(1)
        if ~neighb,
            initial = [];
        end
        t1 = (i1-1)*n+1:i1*n;
        t2 = N(2)-n+1:N(2);
        [x(t1,t2),initial] = recover_block(y(t1,t2),0,T,control,initial);
        if verb, waitbar(((m(1)+1)*m(2)+i1)/blocksToProcess); end
    end
end
%%%%%%%%%%%%%%%%%%%% process the right bottom block %%%%%%%%%%%%%%%%%%%%%%%
if dim == 2 && N(1) ~= m(1)*n && N(2) ~= m(2)*n
    t1 = N(1)-n+1:N(1);
    t2 = N(2)-n+1:N(2);
    x(t1,t2) = recover_block(y(t1,t2),0,T,control,[]);
    if verb, waitbar(1.0); end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if verb, close(wb); end
end