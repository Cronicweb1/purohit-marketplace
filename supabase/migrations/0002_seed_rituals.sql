-- Launch catalogue. Only ~7 of the 16 Sanskars carry real booking volume:
-- Simantonnayana, Namakarana, Annaprashana, Chudakarana, Upanayana, Vivaha,
-- Antyeshti. The rest are seeded for completeness.

insert into ritual_groups (slug, name, description, sort_order) values
  ('sanskars', '16 Sanskars', 'Hindu life-cycle rites. UI-only grouping — the list is not canonical and may hold more than 16 rows.', 1),
  ('puja',     'Pujas & Havans', 'Home and temple ceremonies', 2),
  ('paath',    'Paath & Katha',  'Recitations and discourses', 3),
  ('special',  'Specialisations','Claimable expertise, not directly bookable', 9)
on conflict (slug) do nothing;

-- 16 Sanskars — stored INDIVIDUALLY. Never a Dart enum.
insert into rituals (slug, name, name_hi, aliases, group_id, bookable, claimable, typical_duration_minutes, is_multi_day, sort_order)
select v.slug, v.name, v.name_hi, v.aliases, g.id, v.bookable, true, v.mins, v.multi, v.ord
from (values
  ('garbhadhana',    'Garbhadhana',    'गर्भाधान',      array['conception']::text[],                                     false, 60,  false, 1),
  ('pumsavana',      'Pumsavana',      'पुंसवन',       array['pumsavan']::text[],                                       true,  60,  false, 2),
  ('simantonnayana', 'Simantonnayana', 'सीमन्तोन्नयन',  array['godh bharai','godbharai','baby shower']::text[],          true,  90,  false, 3),
  ('jatakarma',      'Jatakarma',      'जातकर्म',      array['jatkarma','birth ritual']::text[],                        true,  60,  false, 4),
  ('namakarana',     'Namakarana',     'नामकरण',       array['namkaran','naamkaran','naming ceremony']::text[],         true,  90,  false, 5),
  ('nishkramana',    'Nishkramana',    'निष्क्रमण',     array['nishkraman','first outing']::text[],                      true,  60,  false, 6),
  ('annaprashana',   'Annaprashana',   'अन्नप्राशन',    array['annaprashan','first rice','mukhe bhat']::text[],          true,  90,  false, 7),
  ('chudakarana',    'Chudakarana',    'चूड़ाकर्ण',     array['mundan','chudakarma','tonsure','first haircut']::text[],  true,  90,  false, 8),
  ('karnavedha',     'Karnavedha',     'कर्णवेध',       array['ear piercing','kaan chedan']::text[],                     true,  60,  false, 9),
  ('vidyarambha',    'Vidyarambha',    'विद्यारम्भ',    array['vidyarambham','aksharabhyasam']::text[],                  true,  60,  false, 10),
  ('upanayana',      'Upanayana',      'उपनयन',        array['janeu','janoi','thread ceremony','yagnopavit','munja']::text[], true, 180, false, 11),
  ('vedarambha',     'Vedarambha',     'वेदारम्भ',      array['vedarambham']::text[],                                    true,  90,  false, 12),
  ('keshanta',       'Keshanta',       'केशान्त',       array['first shave']::text[],                                    true,  60,  false, 13),
  ('samavartana',    'Samavartana',    'समावर्तन',      array['convocation']::text[],                                    true,  90,  false, 14),
  ('vivaha',         'Vivaha',         'विवाह',        array['shaadi','vivah','wedding','marriage','lagna']::text[],    true,  480, true,  15),
  -- Antyeshti: a grieving family cannot run post -> bid -> compare. Ships NOT
  -- bookable; enable only with the urgency='immediate' broadcast path.
  ('antyeshti',      'Antyeshti',      'अन्त्येष्टि',    array['funeral','last rites','cremation','antim sanskar']::text[], false, 180, false, 16)
) as v(slug,name,name_hi,aliases,bookable,mins,multi,ord)
cross join ritual_groups g where g.slug = 'sanskars'
on conflict (slug) do nothing;

-- Pujas & Havans
insert into rituals (slug, name, name_hi, aliases, group_id, bookable, claimable, typical_duration_minutes, sort_order)
select v.slug, v.name, v.name_hi, v.aliases, g.id, true, true, v.mins, v.ord
from (values
  ('griha-pravesh',    'Griha Pravesh',        'गृह प्रवेश',    array['housewarming','house warming','new home puja']::text[], 180, 1),
  ('satyanarayan',     'Satyanarayan Puja',    'सत्यनारायण',   array['satyanarayana','satya narayan katha']::text[],         180, 2),
  ('rudrabhishek',     'Rudrabhishek',         'रुद्राभिषेक',    array['rudra abhishek','shiv abhishek']::text[],              150, 3),
  ('vastu-puja',       'Vastu Puja',           'वास्तु पूजा',    array['vaastu','vastu shanti']::text[],                       120, 4),
  ('ganesh-puja',      'Ganesh Puja',          'गणेश पूजा',     array['ganpati puja','ganapati']::text[],                      90, 5),
  ('navagraha-shanti', 'Navagraha Shanti',     'नवग्रह शान्ति',  array['graha shanti','navgrah']::text[],                      180, 6),
  ('mahamrityunjaya',  'Mahamrityunjaya Jaap', 'महामृत्युंजय',   array['mahamrityunjay','mrityunjaya jaap']::text[],           240, 7),
  ('bhoomi-pujan',     'Bhoomi Pujan',         'भूमि पूजन',     array['bhumi pujan','ground breaking']::text[],               120, 8)
) as v(slug,name,name_hi,aliases,mins,ord)
cross join ritual_groups g where g.slug = 'puja'
on conflict (slug) do nothing;

-- Paath & Katha
insert into rituals (slug, name, name_hi, aliases, group_id, bookable, claimable, typical_duration_minutes, is_multi_day, sort_order)
select v.slug, v.name, v.name_hi, v.aliases, g.id, true, true, v.mins, v.multi, v.ord
from (values
  ('sunderkand',       'Sunderkand Paath', 'सुन्दरकाण्ड',   array['sundarkand','sunder kand']::text[],        180, false, 1),
  ('ramayan-path',     'Ramayan Path',     'रामायण पाठ',    array['ramayana paath','akhand ramayan']::text[], 480, true,  2),
  ('bhagwat-katha',    'Bhagwat Katha',    'भागवत कथा',     array['bhagavat katha','saptah']::text[],         480, true,  3),
  ('durga-saptashati', 'Durga Saptashati', 'दुर्गा सप्तशती',  array['chandi path','durga path']::text[],        240, false, 4)
) as v(slug,name,name_hi,aliases,mins,multi,ord)
cross join ritual_groups g where g.slug = 'paath'
on conflict (slug) do nothing;

-- Specialisations: claimable but NOT bookable. These are not rituals.
insert into rituals (slug, name, name_hi, aliases, group_id, bookable, claimable, sort_order)
select v.slug, v.name, v.name_hi, v.aliases, g.id, false, true, v.ord
from (values
  ('vedic-knowledge', 'Vedic Knowledge', 'वेद ज्ञान',     array['vedas','vedic studies']::text[],           1),
  ('jyotishacharya',  'Jyotishacharya',  'ज्योतिषाचार्य',  array['astrology','jyotish','kundli']::text[],    2),
  ('kathavachak',     'Kathavachak',     'कथावाचक',       array['katha vachak','storyteller']::text[],      3),
  ('karmakandi',      'Karmakandi',      'कर्मकाण्डी',     array['karma kandi','ritual specialist']::text[], 4)
) as v(slug,name,name_hi,aliases,ord)
cross join ritual_groups g where g.slug = 'special'
on conflict (slug) do nothing;

-- Phase 0 launches in ONE city — recruit 20-30 purohits there by hand.
insert into cities (name, state, lat, lng) values
  ('Delhi','Delhi',28.6139,77.2090),
  ('Noida','Uttar Pradesh',28.5355,77.3910),
  ('Gurugram','Haryana',28.4595,77.0266),
  ('Mumbai','Maharashtra',19.0760,72.8777),
  ('Pune','Maharashtra',18.5204,73.8567),
  ('Bengaluru','Karnataka',12.9716,77.5946),
  ('Hyderabad','Telangana',17.3850,78.4867),
  ('Varanasi','Uttar Pradesh',25.3176,82.9739),
  ('Jaipur','Rajasthan',26.9124,75.7873),
  ('Lucknow','Uttar Pradesh',26.8467,80.9462)
on conflict do nothing;
