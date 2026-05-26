const supabase = require('../firebase/firebaseConfig');

async function getCustomerProfile(customerId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, phone, avatar_url')
    .eq('id', customerId)
    .single();
  if (error) throw error;
  return data;
}

async function updateCustomerProfile(customerId, { name, phone }) {
  const patch = {};
  if (name !== undefined) patch.name = name;
  if (phone !== undefined) patch.phone = phone;

  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', customerId)
    .select('id, name, phone, avatar_url')
    .single();
  if (error) throw error;
  return data;
}

async function getVehicles(customerId) {
  const { data, error } = await supabase
    .from('vehicles')
    .select('*')
    .eq('owner_id', customerId)
    .order('created_at', { ascending: true });
  if (error) throw error;
  return data;
}

async function addVehicle(customerId, vehicle) {
  const { data, error } = await supabase
    .from('vehicles')
    .insert({ ...vehicle, owner_id: customerId })
    .select('*')
    .single();
  if (error) throw error;
  return data;
}

async function deleteVehicle(customerId, vehicleId) {
  const { error } = await supabase
    .from('vehicles')
    .delete()
    .eq('id', vehicleId)
    .eq('owner_id', customerId);
  if (error) throw error;
}

module.exports = { getCustomerProfile, updateCustomerProfile, getVehicles, addVehicle, deleteVehicle };
