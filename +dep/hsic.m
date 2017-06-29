% HSIC                        Hilbert-Schmidt Independence Criterion
% 
%     [stat,K,L,sigmax,sigmay] = hsic(x,y,varargin)
%
%     INPUTS
%     x - [m x p] m samples of dimensionality p
%     y - [m x q] m samples of dimensionality q
%
%     OPTIONAL (name/value pairs)
%     sigmax - gaussian bandwidth, default = median heuristic
%     sigmay - gaussian bandwidth, default = median heuristic
%     biased - boolean indicated biased estimator (default=false)
%
%     OUTPUTS
%     h - Hilbert-Schmidt Independence Criterion
%
%     REFERENCE
%     Gretton et al (2008). A kernel statistical test of independence. NIPS
%     Song et al (2012). Feature Selection via Dependence Maximization.
%       Journal of Machine Learning Research 13: 1393-1434
%
%     SEE ALSO
%     hsictest

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

function [h,K,L,sigmax,sigmay] = hsic(x,y,varargin)

par = inputParser;
par.KeepUnmatched = true;
addRequired(par,'x',@isnumeric);
addRequired(par,'y',@isnumeric);
addParamValue(par,'sigmax',[],@isnumeric);
addParamValue(par,'sigmay',[],@isnumeric);
addParamValue(par,'unbiased',false,@(x) isnumeric(x) || islogical(x));
addParamValue(par,'gram',false,@isscalar);
addParamValue(par,'doublecenter',false,@isscalar);
parse(par,x,y,varargin{:});

[m,p] = size(x);
[n,q] = size(y);
assert(m == n,'HSIC requires x and y to have the same # of samples');

% error on doublecenter = true && unbiased

if par.Results.doublecenter
   Kc = x;
   Lc = y;
elseif par.Results.gram
   K = x;
   L = y;
else
   if isempty(par.Results.sigmax)
      % Median heuristic, Gretton et al. 2012
      sigmax = sqrt(0.5*median(pdist(x).^2));
   else
      sigmax = par.Results.sigmax;
   end
   
   if isempty(par.Results.sigmay)
      sigmay = sqrt(0.5*median(pdist(y).^2));
   else
      sigmay = par.Results.sigmay;
   end
   
   K = utils.rbf(sigmax,x);
   L = utils.rbf(sigmay,y);
end

% Song et al. eq 4, 5
if par.Results.unbiased
   K = utils.zerodiag(K);
   L = utils.zerodiag(L);
   l = ones(m,1);
   h = trace(K*L) + (l'*K*l*l'*L*l)/(m-1)/(m-2) - 2*(l'*K*L*l)/(m-2);
   h = h/m/(m-3);
else
   if ~exist('Kc','var')
      H = eye(m) - ones(m)/m;
      Kc = K*H;
      Lc = L*H;
   end
   h = sum(sum(Kc.*Lc))/m^2;
   %h = sum(sum((H*K*H)'.*L))/m^2;
   %h = trace(Kc*Lc)/m^2;
   %h = trace(H*K*H*H*L*H)/m^2
   %h = sum(sum((H*K*H).*(H*L*H)))/m^2;
end