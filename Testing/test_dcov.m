dep.dcov([1 2 3 4]',[1 1 2 6]')
dep.dcorr([1 2 3 4]',[1 1 2 6]')
dep.dcov([1 2 3]',[.5 2 3.4]')
dep.dcorr([1 2 3]',[.5 2 3.4]')
dep.dcov([-11 2 3]',[.5 2 3.4]')
dep.dcorr([-11 2 3]',[.5 2 3.4]')

% energy package 1.6.2
% > dcov(c(1,2,3,4),c(1,1,2,6))
% [1] 1.118034
% > dcor(c(1,2,3,4),c(1,1,2,6))
% [1] 0.8947853
% > dcov(c(1,2,3),c(.5,2,3.4))
% [1] 0.846197
% > dcor(c(1,2,3),c(.5,2,3.4))
% [1] 0.9998217
% > dcov(c(-11,2,3),c(.5,2,3.4))
% [1] 2.258591
% > dcor(c(-11,2,3),c(.5,2,3.4))
% [1] 0.9206351

