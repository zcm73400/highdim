% HSICTEST                    HSIC test of independence
% 
%     [pval,h,stat] = hsictest(x,y,varargin)
%
%     Given a sample X1,...,Xm from a p-dimensional multivariate distribution,
%     and a sample Y1,...,Xm from a q-dimensional multivariate distribution,
%     test the hypothesis:
%
%     H0 : X and Y are mutually independent
%
%     This hypothesis is tested using several different permutation methods. 
%
%     The default permutation method avoids permuting the data altogether 
%     by approximating the permutation distribution using a moment-matched 
%     Pearson Type III distribution (Bilodeau & Guetsop Nangue 2017; Josse 
%     et al 2008; Minas & Montana 2014). The first three moments of the 
%     permutation distribution can be calculated exactly for HSIC and related 
%     statistics (Kazi-Aoual et al 1995), and are robust and accurate (Josse 
%     et al 2008). Since this method does not actually permute the data, it 
%     is very fast, achieving the same statistical power that would otherwise 
%     require millions of permutations (Minas & Montana, 2014).
%
%     The Gamma approximation proposed by Gretton et al (2008) is also
%     implemented for completeness, although this is inferior to the Pearson 
%     Type III approximation and should not be used (Bilodeau & Guetsop 
%     Nangue 2017).
%
%     Testing using actual permutations of the data are also implemented.
%     Naive permutation of the rows of X or Y is expensive due to O(n^2) 
%     distance calculations. This can be avoided since it is equivalent to 
%     simultaneously permuting the rows and columns of the distance matrix, 
%     and recomputing the statistic with the permuted distance matrix.
%
%     INPUTS
%     x - [m x p] m samples of dimensionality p
%     y - [m x q] m samples of dimensionality q
%
%     OPTIONAL (name/value pairs)
%     sigmax - gaussian bandwidth, default = median heuristic
%     sigmay - gaussian bandwidth, default = median heuristic
%     unbiased - boolean indicated biased estimator (default=false)
%     method - 'pearson'    - Pearson type III approx by moment matching,
%                             first 3 moments (DEFAULT)
%              'gamma'      - Gamma approximation, first 2 moments
%              'perm'       - randomization using permutation of the rows &
%                             columns of the double-centered distance matrices
%              'perm-dist'  - randomization using permutation of the rows &
%                             columns of distance matrices
%              'perm-brute' - brute force randomization, directly permuting
%                             one of the inputs, which requires recalculating 
%                             and centering distance matrices
%     nboot - # permutations if method != 'pearson'
%
%     OUTPUTS
%     pval - p-value
%     stat - HSIC
%     boot - bootstrap samples 
%
%     REFERENCE
%     Bilodeau & Guetsop Nangue (2017). Approximations to permutation tests 
%       of independence between two random vectors. 
%       Computational Statistics & Data Analysis, submitted.
%     Gretton et al (2008). A kernel statistical test of independence. NIPS
%     Josse, Pages & Husson (2008). Testing the significance of the RV 
%       coefficient. Computational Statistics and Data Analysis. 53: 82-91
%     Kazi-Aoual et al (1995). Refined approximations to permutation tests 
%       for multivariate inference. Computational Statistics & Data Analysis.
%       20: 643-656
%     Minas & Montana (2014). Distance-based analysis of variance: 
%       Approximate inference. Statistical Analysis & Data Mining. 7: 450-470
%     Song et al (2012). Feature Selection via Dependence Maximization.
%       Journal of Machine Learning Research 13: 1393-1434
%
%     SEE ALSO
%     hsic, DepTest2

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

function [pval,h,stat] = hsictest(x,y,varargin)

par = inputParser;
par.KeepUnmatched = true;
addRequired(par,'x',@isnumeric);
addRequired(par,'y',@isnumeric);
addParamValue(par,'method','pearson',@ischar);
addParamValue(par,'nboot',999,@(x) isnumeric(x) && isscalar(x));
parse(par,x,y,varargin{:});

m = size(x,1);
n = size(y,1);
assert(m == n,'HSIC requires x and y to have the same # of samples');

nboot = par.Results.nboot;

switch lower(par.Results.method)
   case {'pearson'}
      [h,K,L] = dep.hsic(x,y,par.Unmatched);
      A = K - bsxfun(@plus,mean(K),mean(K,2)) + mean(K(:));
      B = L - bsxfun(@plus,mean(L),mean(L,2)) + mean(L(:));

      [mu,sigma2,skew] = utils.permMoments(A,B); % Exact moments
      
      stat = sum(sum(A.*B));
      stat = (stat - mu)/sqrt(sigma2);
      if skew >= 0
         pval = gamcdf(stat - (-2/skew),4/skew^2,skew/2,'upper');
      else
         as = abs(skew);
         pval = gamcdf(skew/as*stat + 2/as,4/skew^2,as/2);         
      end
      
      return;
   case {'gamma'}
      [h,K,L] = dep.hsic(x,y,par.Unmatched);
      H = eye(m) - ones(m)/m;
      Kc = H*K*H;
      Lc = H*L*H;
      
      % Variance under H0
      sigma2 = (1/6 * Kc.*Lc).^2;
      sigma2 = 1/m/(m-1)* ( sum(sum(sigma2)) - sum(diag(sigma2)) );
      sigma2 = 72*(m-4)*(m-5)/m/(m-1)/(m-2)/(m-3) * sigma2;
      
      % Mean under H0
      K = K - diag(diag(K));
      L = L - diag(diag(L));
      l = ones(m,1);
      muX = 1/m/(m-1)*l'*(K*l);
      muY = 1/m/(m-1)*l'*(L*l);
      mu  = 1/m * ( 1 + muX*muY  - muX - muY );  %mean under H0

      stat = m*h;
      pval = gamcdf(stat,mu^2/sigma2,sigma2*m/mu,'upper');
      
      return;
   case {'perm'}
      if isfield(par.Unmatched,'unbiased') && par.Unmatched.unbiased
         % This only works for BIASED estimator, since gram matrices are
         % necessary for calculating the UNBIASED estimator
         error('Cannot use unbiased estimator for method = ''perm''');
      end
      [h,K,L] = dep.hsic(x,y,par.Unmatched);
      H = eye(m) - ones(m)/m;
      Kc = H*K*H;
      
      stat = zeros(nboot,1);
      for i = 1:nboot
         ind = randperm(m);
         stat(i) = sum(sum(Kc'.*L(ind,ind)))/m^2;
      end
   case {'perm-gram'}
      [h,K,L] = dep.hsic(x,y,par.Unmatched);
      
      stat = zeros(nboot,1);
      for i = 1:nboot
         ind = randperm(m);
         stat(i) = dep.hsic(K,L(ind,ind),'gram',true,par.Unmatched);
      end
   case {'perm-brute'}
      h = dep.hsic(x,y,par.Unmatched);

      stat = zeros(nboot,1);
      for i = 1:nboot
         ind = randperm(n);
         stat(i) = dep.hsic(x,y(ind,:),par.Unmatched);
      end
   otherwise
      error('Unrecognized test method');
end

pval = (1 + sum(stat>h)) / (1 + nboot);
