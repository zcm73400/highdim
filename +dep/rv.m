% RV                          RV coefficient of dependence
% 
%     [r,xx,yy] = rv(x,y,type,demean)
%
%     INPUTS
%     x - [n x p] n samples of dimensionality p
%     y - [n x q] n samples of dimensionality q
%
%     OPTIONAL
%     type - 'mod' to calculate modified RV (Smiles et al), default='standard'
%     demean - boolean indicating to subtract mean for each var, default=TRUE
%
%     OUTPUTS
%     r  - RV coefficient
%     xx - inner product matrix of x
%     yy - inner product matrix of y 
%
%     REFERENCE
%     Smilde et al (2009). Matrix correlations for high-dimensional data: 
%       the modified RV-coefficient. Bioinformatics 25: 401-405
%
%     SEE ALSO
%     rvtest, dcorr, dcorrtest

%     $ Copyright (C) 2014 Brian Lau http://www.subcortex.net/ $
%     The full license and most recent version of the code can be found at:
%     https://github.com/brian-lau/highdim
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [r,xx,yy] = rv(x,y,type,demean)

if nargin < 4
   demean = true;
end

if nargin < 3
   type = '';
end

[n,~] = size(x);
if n ~= size(y,1)
   error('RV requires x and y to have the same # of samples');
end

if demean
   x = bsxfun(@minus,x,mean(x));
   y = bsxfun(@minus,y,mean(y));
end
xx = x*x';
yy = y*y';

switch lower(type)
   case {'mod'}
      dind = 1:(n+1):n*n;
      xx(dind) = xx(dind) - diag(xx);
      yy(dind) =  yy(dind) - diag(yy);
      r = trace(xx*yy) / sqrt(trace(xx^2)*trace(yy^2));
   otherwise
      r = trace(xx*yy) / sqrt(trace(xx^2)*trace(yy^2));
end