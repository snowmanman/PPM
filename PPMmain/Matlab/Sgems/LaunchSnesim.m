%
% This function writes a command file for Sgems and then launches snesim
%
% Author: Celine Scheidt
% Date: November 2009
% Modified May 2011


function LaunchSnesim(Prj_name,seed,snesim_input,Nreal,filename,Marginal_Cdf,probacube_file)

% Input Parameters:
%   - Prj_name:  Name of the project containing TI and well information
%   - seed:  Random seed
%   - snesim_input:  contains all snesim input (size of the grid, search
%                    template, etc.)
%   - Nreal: Number of realizations to generate
%   - filename:  name of the file to save realizations in gslib format
%   - Marginal_Cdf:  vector containing the prior probability of each facies
%   - probacube_file: (Optional) File with probability cubes (soft data) in sgems
%                     format 
    
   % define values by default if not given in snesim_input
   snesim_input = set_default_values(snesim_input);
    
   
   nb_facies = length(Marginal_Cdf);
   
   fid = fopen('snesim.bat','w');  % Command file which will be called by Sgems
   
   fprintf(fid,['LoadProject ' Prj_name '\n']);
   fprintf(fid,'NewCartesianGrid  sim_grid::%i::%i::%i::%.1f::%.1f::%.1f::0::0::0\n',snesim_input.nx,snesim_input.nx,snesim_input.nz, ...
    snesim_input.dx,snesim_input.dy,snesim_input.dz);
   fprintf(fid,'NewCartesianGrid  temp::%i::%i::%i::%.1f::%.1f::%.1f::0::0::0\n',snesim_input.nx,snesim_input.nx,snesim_input.nz, ...
    snesim_input.dx,snesim_input.dy,snesim_input.dz);
   
    if nargin == 7
        fprintf(fid,['LoadObjectFromFile  ' probacube_file '::All' '\n']);
        for i = 1:nb_facies
            fprintf(fid,'CopyProperty  probacube::z%i::sim_grid::soft_facies%i::0::0 \n',i,i);
        end
    end
   
   fprintf(fid,'RunGeostatAlgorithm  snesim_std::/GeostatParamUtils/XML::<parameters>  <algorithm name="snesim_std" />     ');
   fprintf(fid,'<GridSelector_Sim value="sim_grid" region=""  />     <Property_Name_Sim  value="real" />     ');
   fprintf(fid,'<Nb_Realizations  value="%i" />   <Seed  value="%d" />     ',Nreal,seed);
   fprintf(fid,'<PropertySelector_Training  grid="%s" region="" property="facies"  />  ',snesim_input.TIname);
   fprintf(fid,'<Nb_Facies  value="%i" />  ',nb_facies);
   fprintf(fid,'<Marginal_Cdf  value="');
   for i = 1:nb_facies
       fprintf(fid,'%.2f  ',Marginal_Cdf(i));
   end
   fprintf(fid,'" />   ');
   fprintf(fid,'<Max_Cond  value="%i" />     ',snesim_input.maxcondval);
   fprintf(fid,'<Search_Ellipsoid  value="%i %i %i  %i %i %i" />   ',snesim_input.range_max,snesim_input.range_med,snesim_input.range_min, ...
       snesim_input.angle_az,snesim_input.angle_dip,snesim_input.angle_rake);
   fprintf(fid,'<Hard_Data  grid="wells" region="" property="facies"  />     ');
   
   if nargin < 7  % no soft data
       fprintf(fid,'<Use_ProbField  value="0"  />     <ProbField_properties count="0"   value=""  />     ');
       
   else  % soft data       
       fprintf(fid,'<Use_ProbField  value="1"  />     <ProbField_properties count="%i"   value="',nb_facies );
       for i = 1:nb_facies-1
            fprintf(fid,'soft_facies%i;',i );
       end
       fprintf(fid,'soft_facies%i"  />     ',nb_facies);
   end
   
   fprintf(fid,'<TauModelObject  value="%.2f %.2f" />     ',snesim_input.tau1,snesim_input.tau2);
   fprintf(fid,'<VerticalPropObject value="" region=""  />     <VerticalProperties count="0"   value=""  />     ');
   fprintf(fid,'<Use_Affinity  value="0"  />     <Use_Rotation  value="0"  />     ');
   fprintf(fid,'<Cmin  value="1" />     <Constraint_Marginal_ADVANCED  value="%.2f" />     ',snesim_input.servosystem);
   fprintf(fid,'<resimulation_criterion  value="-1" />     <resimulation_iteration_nb  value="1" />     ');
   fprintf(fid,'<Nb_Multigrids_ADVANCED  value="3" />     <Debug_Level  value="0" />     <Subgrid_choice  value="0"  />     ');
   fprintf(fid,'<expand_isotropic  value="1"  />     <expand_anisotropic  value="0"  />     <aniso_factor  value="    " />     ');
   fprintf(fid,'<Region_Indicator_Prop  value=""  />     <Active_Region_Code  value="" />     <Use_Previous_Simulation  value="0"  />    ');
   fprintf(fid,'<Use_Region  value="0"  />     ');
   fprintf(fid,'</parameters>\n');
   
   % Save the realizations in gslib format
   fprintf(fid,['SaveGeostatGrid  sim_grid::' filename '::gslib::0::']);
   for i = 1:Nreal
       fprintf(fid,'::real__real%i',i-1);
   end
   fprintf(fid,'\n');
   fclose(fid);
    
    % Call Snesim
    dos('D:\Softwares\SGeMS-win32-Beta\sgems-win32.exe snesim.bat > sgems.out');
    
end

%
% This function defines default values for snesim
%


function snesim_input = set_default_values(snesim_input)
    if ~ isfield(snesim_input,'Nb_Multigrids')
       snesim_input.Nb_Multigrids = 3;
    end
    if ~ isfield(snesim_input,'dx')
       snesim_input.dx = 1;
    end
    if ~ isfield(snesim_input,'dy')
       snesim_input.dy = 1;
    end
    if ~ isfield(snesim_input,'dz')
       snesim_input.dz = 1;
    end
    if ~ isfield(snesim_input,'angle_az')
       snesim_input.angle_az = 0;
    end
    if ~ isfield(snesim_input,'angle_dip')
       snesim_input.angle_dip = 0;
    end
    if ~ isfield(snesim_input,'angle_rake')
       snesim_input.angle_rake = 0;
    end
    if ~ isfield(snesim_input,'tau1')
       snesim_input.tau1 = 1;
    end
    if ~ isfield(snesim_input,'tau2')
       snesim_input.tau2 = 1;
    end
    if ~ isfield(snesim_input,'servosystem')
        snesim_input.servosystem = 0.5;
    end
end
