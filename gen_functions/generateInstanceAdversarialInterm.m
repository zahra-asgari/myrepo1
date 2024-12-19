function [instance] = generateInstanceAdversarialInterm(old_instance, instance_folder, dataname, tp_map)
%generateInstances this function generates a random instance to be later
%simulated
%
% [instance] = generateInstances()
%
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:29:44 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
addpath('utils', 'radio', 'gen_scripts');
%these are local options that should be set to 1 only for debug

%% 

n_tp = size(tp_map,1);
ris_p_mask = old_instance.acc_p_mask(tp_map,:,:);
smallest_angles = old_instance.angsep(tp_map,:,:);


%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model
instance.n_donors=old_instance.n_donors;
instance.n_ris = old_instance.n_ris;
instance.n_tp=n_tp;

instance.acc_p_mask = ris_p_mask;
%instance.forbidden_assoc = x_history(:,donor_cs_map, ris_cs_map);

instance.max_tp = old_instance.max_tp;
instance.A_max = old_instance.A_max;
instance.A_min = 1;

instance.angsep = smallest_angles;


instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
