const supabase = require('../firebase/firebaseConfig');

async function getCustomerProfile(customerId, { name, email } = {}) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, phone, avatar_url')
    .eq('id', customerId)
    .maybeSingle();
  if (error) throw error;

  if (data) return data;

  // Profile row missing (Supabase trigger may not have fired for this user).
  // Upsert now so the app never sees a "no profile" error state.
  const fallbackName = name ?? (email ? email.split('@')[0] : 'User');
  const { data: created, error: ce } = await supabase
    .from('profiles')
    .upsert({ id: customerId, role: 'customer', name: fallbackName }, { onConflict: 'id' })
    .select('id, name, phone, avatar_url')
    .single();
  if (ce) throw ce;
  return created;
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
