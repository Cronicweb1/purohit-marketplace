-- 0004_institutions.sql
-- A curated registry of Gurukuls, Veda Pathashalas and Sanskrit universities so
-- a purohit picks their alma mater from a list instead of free-typing it. Free
-- text is still accepted by the UI (the list can never be exhaustive) but a
-- picked value normalises spelling, which is what makes admin review fast.
--
-- Anon-readable like `cities` and `rituals`: a purohit needs this list on the
-- registration screen, which is reachable before their profile row exists.

create table if not exists public.institutions (
  id          bigint generated always as identity primary key,
  name        text not null,
  city        text,
  state       text,
  kind        text not null default 'gurukul'
                check (kind in ('gurukul','pathshala','university','other')),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create unique index if not exists institutions_name_state_uq
  on public.institutions (lower(name), lower(coalesce(state,'')));

create index if not exists institutions_state_idx on public.institutions (state);

alter table public.institutions enable row level security;

drop policy if exists institutions_read on public.institutions;
create policy institutions_read on public.institutions
  for select using (true);

insert into public.institutions (name, city, state, kind)
select v.name, v.city, v.state, v.kind
from (values
  ('Shri Lal Bahadur Shastri National Sanskrit University','New Delhi','Delhi','university'),
  ('Central Sanskrit University (Rashtriya Sanskrit Sansthan)','New Delhi','Delhi','university'),
  ('Sampurnanand Sanskrit Vishwavidyalaya','Varanasi','Uttar Pradesh','university'),
  ('Faculty of Sanskrit Vidya Dharma Vigyan, Banaras Hindu University','Varanasi','Uttar Pradesh','university'),
  ('Kameshwar Singh Darbhanga Sanskrit University','Darbhanga','Bihar','university'),
  ('Rashtriya Sanskrit Vidyapeeth','Tirupati','Andhra Pradesh','university'),
  ('Sri Venkateswara Vedic University','Tirupati','Andhra Pradesh','university'),
  ('Shree Jagannath Sanskrit University','Puri','Odisha','university'),
  ('Sree Sankaracharya University of Sanskrit','Kalady','Kerala','university'),
  ('Kavikulaguru Kalidas Sanskrit University','Ramtek','Maharashtra','university'),
  ('Jagadguru Ramanandacharya Rajasthan Sanskrit University','Jaipur','Rajasthan','university'),
  ('Shree Somnath Sanskrit University','Veraval','Gujarat','university'),
  ('Uttarakhand Sanskrit University','Haridwar','Uttarakhand','university'),
  ('Maharishi Panini Sanskrit Evam Vedic Vishwavidyalaya','Ujjain','Madhya Pradesh','university'),
  ('Maharishi Mahesh Yogi Vedic Vishwavidyalaya','Katni','Madhya Pradesh','university'),
  ('Sanchi University of Buddhist-Indic Studies','Sanchi','Madhya Pradesh','university'),
  ('Karnataka Samskrit University','Bengaluru','Karnataka','university'),
  ('Kumar Bhaskar Varma Sanskrit and Ancient Studies University','Nalbari','Assam','university'),
  ('Chinmaya Vishwavidyapeeth','Kochi','Kerala','university'),
  ('Maharishi Valmiki Sanskrit University','Kaithal','Haryana','university'),
  ('The Sanskrit College and University','Kolkata','West Bengal','university'),
  ('Tilak Maharashtra Vidyapeeth','Pune','Maharashtra','university'),
  ('Gurukula Kangri Vishwavidyalaya','Haridwar','Uttarakhand','university'),
  ('Dev Sanskriti Vishwavidyalaya','Haridwar','Uttarakhand','university'),
  ('Deccan College Post-Graduate and Research Institute','Pune','Maharashtra','university'),
  ('Bhandarkar Oriental Research Institute','Pune','Maharashtra','university'),
  ('Vaidika Samshodhana Mandala','Pune','Maharashtra','university'),
  ('Kuppuswami Sastri Research Institute','Chennai','Tamil Nadu','university'),
  ('Adyar Library and Research Centre','Chennai','Tamil Nadu','university'),
  ('Oriental Research Institute, Mysore','Mysuru','Karnataka','university'),
  ('Poornaprajna Vidyapeetha','Bengaluru','Karnataka','university'),
  ('Purnaprajna Samshodhana Mandiram','Bengaluru','Karnataka','university'),
  ('Rashtriya Sanskrit Sansthan, Bhopal Campus','Bhopal','Madhya Pradesh','university'),
  ('Rashtriya Sanskrit Sansthan, Jaipur Campus','Jaipur','Rajasthan','university'),
  ('Rashtriya Sanskrit Sansthan, Lucknow Campus','Lucknow','Uttar Pradesh','university'),
  ('Rashtriya Sanskrit Sansthan, Puri Campus','Puri','Odisha','university'),
  ('Rashtriya Sanskrit Sansthan, Guruvayoor Campus','Guruvayur','Kerala','university'),
  ('Rashtriya Sanskrit Sansthan, Shringeri Campus','Sringeri','Karnataka','university'),
  ('Rashtriya Sanskrit Sansthan, Ekalavya Campus','Agartala','Tripura','university'),
  ('Rashtriya Sanskrit Sansthan, Raniket Campus','Almora','Uttarakhand','university'),
  ('Rashtriya Sanskrit Sansthan, Jammu Campus','Jammu','Jammu and Kashmir','university'),
  ('Rashtriya Sanskrit Sansthan, Bhopal Ganganath Jha Campus','Prayagraj','Uttar Pradesh','university'),
  ('Shri Sadvidya Pathashala Sanskrit College','Mysuru','Karnataka','university'),
  ('Madras Sanskrit College','Chennai','Tamil Nadu','university'),
  ('Government Sanskrit College','Thiruvananthapuram','Kerala','university'),
  ('Rajkiya Sanskrit Mahavidyalaya','Ayodhya','Uttar Pradesh','university'),
  ('Sringeri Sharada Peetham Mahapathashala','Sringeri','Karnataka','pathshala'),
  ('Bharadwaja Vedalaya, Sringeri','Sringeri','Karnataka','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Varanasi','Varanasi','Uttar Pradesh','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Haridwar','Haridwar','Uttarakhand','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Nashik','Nashik','Maharashtra','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Gaya','Gaya','Bihar','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Mysuru','Mysuru','Karnataka','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Hyderabad','Hyderabad','Telangana','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Madurai','Madurai','Tamil Nadu','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Chennai','Chennai','Tamil Nadu','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Kanchipuram','Kanchipuram','Tamil Nadu','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Tirupati','Tirupati','Andhra Pradesh','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Coimbatore','Coimbatore','Tamil Nadu','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Rameswaram','Rameswaram','Tamil Nadu','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Kalady','Kalady','Kerala','pathshala'),
  ('Sringeri Sharada Peetham Pathashala, Bengaluru','Bengaluru','Karnataka','pathshala'),
  ('Kanchi Kamakoti Peetam Veda Patasala','Kanchipuram','Tamil Nadu','pathshala'),
  ('Veda Rakshana Nidhi Trust Patasala','Kanchipuram','Tamil Nadu','pathshala'),
  ('Thiaga Sastha Trust Veda Paatashala','Chennai','Tamil Nadu','pathshala'),
  ('Singanallur Narasimha Iyer Vedapatasala','Palakkad','Kerala','pathshala'),
  ('SLMTS Veda Pathashala','Chennai','Tamil Nadu','pathshala'),
  ('Sri Avadhoota Datta Peetham Veda Pathashala','Mysuru','Karnataka','pathshala'),
  ('Sri Ahobila Mutt Sanskrit College','Chennai','Tamil Nadu','pathshala'),
  ('Sri Parimalam Veda Patasala','Srirangam','Tamil Nadu','pathshala'),
  ('Sri Ramachandrapura Mutt Veda Pathashala','Shivamogga','Karnataka','pathshala'),
  ('Uttaradi Mutt Veda Pathashala','Bengaluru','Karnataka','pathshala'),
  ('Raghavendra Swamy Mutt Veda Pathashala','Raichur','Karnataka','pathshala'),
  ('Shri Kashi Vishwanath Sanskrit Vidyalaya','Varanasi','Uttar Pradesh','pathshala'),
  ('Shri Dakshinamurti Veda Pathashala','Varanasi','Uttar Pradesh','pathshala'),
  ('Vedic Research Institute, Kashi','Varanasi','Uttar Pradesh','pathshala'),
  ('Shri Bhagavan Ved Vidya Pratishthan','Ujjain','Madhya Pradesh','pathshala'),
  ('Maharshi Sandipani Rashtriya Ved Vidya Pratishthan','Ujjain','Madhya Pradesh','pathshala'),
  ('Shri Somnath Ved Vidyalaya','Veraval','Gujarat','pathshala'),
  ('Acharya Hemchandra Sanskrit Pathshala','Ahmedabad','Gujarat','pathshala'),
  ('Bansi Gir Goshala Ved Pathshala','Ahmedabad','Gujarat','pathshala'),
  ('Shri Jagannath Ved Vidyalaya','Puri','Odisha','pathshala'),
  ('Tirumala Tirupati Devasthanams Veda Patasala','Tirupati','Andhra Pradesh','pathshala'),
  ('Shri Vishwanath Ved Vidyapeeth','Haridwar','Uttarakhand','pathshala'),
  ('Shri Badrinath Ved Vidyalaya','Badrinath','Uttarakhand','pathshala'),
  ('Panini Mahavidyalaya (Gurukul Rewali)','Sonipat','Haryana','gurukul'),
  ('Gurukul Jhajjar','Jhajjar','Haryana','gurukul'),
  ('Gurukul Kalwa','Jhajjar','Haryana','gurukul'),
  ('Kanya Gurukul Mahavidyalaya','Roorkee','Uttarakhand','gurukul'),
  ('Rajiv Dixit Gurukul','Haridwar','Uttarakhand','gurukul'),
  ('Gurukul Kurukshetra','Kurukshetra','Haryana','gurukul'),
  ('Gurukul Indraprastha','New Delhi','Delhi','gurukul'),
  ('Swaminarayan Gurukul, Rajkot','Rajkot','Gujarat','gurukul'),
  ('Swaminarayan Gurukul, Ahmedabad','Ahmedabad','Gujarat','gurukul'),
  ('Shri Ram Sharma Acharya Gurukul','Haridwar','Uttarakhand','gurukul'),
  ('Chinmaya Mission Sandeepany Sadhanalaya','Mumbai','Maharashtra','gurukul'),
  ('Arsha Vidya Gurukulam','Coimbatore','Tamil Nadu','gurukul'),
  ('Arsha Vidya Peetham','Rishikesh','Uttarakhand','gurukul'),
  ('Parmarth Niketan Ved Niketan Gurukul','Rishikesh','Uttarakhand','gurukul'),
  ('Kailash Ashram Brahma Vidya Peetham','Rishikesh','Uttarakhand','gurukul'),
  ('Shri Ved Vidyalaya, Indore','Indore','Madhya Pradesh','gurukul'),
  ('Shri Ved Vidyalaya, Jabalpur','Jabalpur','Madhya Pradesh','gurukul'),
  ('Shri Ved Vidyalaya, Gwalior','Gwalior','Madhya Pradesh','gurukul'),
  ('Chitrakoot Ved Vidyalaya','Chitrakoot','Madhya Pradesh','gurukul'),
  ('Amarkantak Ved Vidyalaya','Amarkantak','Madhya Pradesh','gurukul'),
  ('Maheshwar Ved Vidyalaya','Maheshwar','Madhya Pradesh','gurukul'),
  ('Omkareshwar Ved Vidyalaya','Omkareshwar','Madhya Pradesh','gurukul'),
  ('Gayatri Shaktipeeth Gurukul','Bhopal','Madhya Pradesh','gurukul'),
  ('Shri Sant Asharamji Gurukul','Ahmedabad','Gujarat','gurukul'),
  ('Vidya Bharati Gurukul','Nagpur','Maharashtra','gurukul'),
  ('Shri Mathuradheesh Ved Pathshala','Mathura','Uttar Pradesh','gurukul'),
  ('Shri Vrindavan Ved Vidyapeeth','Vrindavan','Uttar Pradesh','gurukul'),
  ('Shri Ayodhya Ved Vidyalaya','Ayodhya','Uttar Pradesh','gurukul'),
  ('Naimisharanya Ved Vidyalaya','Naimisharanya','Uttar Pradesh','gurukul'),
  ('Shri Ganga Ved Vidyalaya','Prayagraj','Uttar Pradesh','gurukul'),
  ('Nabadwip Sanskrit Tol','Nabadwip','West Bengal','gurukul'),
  ('Bhadrachalam Veda Pathashala','Bhadrachalam','Telangana','pathshala'),
  ('Yadagirigutta Veda Pathashala','Yadagirigutta','Telangana','pathshala'),
  ('Guruvayur Devaswom Veda Pathashala','Guruvayur','Kerala','pathshala'),
  ('Thrissur Brahmaswam Madham','Thrissur','Kerala','pathshala'),
  ('Pandharpur Ved Pathshala','Pandharpur','Maharashtra','pathshala'),
  ('Trimbakeshwar Ved Vidyalaya','Nashik','Maharashtra','pathshala'),
  ('Shirdi Sai Ved Pathshala','Shirdi','Maharashtra','pathshala'),
  ('Pushkar Ved Vidyalaya','Pushkar','Rajasthan','gurukul'),
  ('Nathdwara Ved Pathshala','Nathdwara','Rajasthan','gurukul'),
  ('Dwarka Sharada Peetham Ved Pathshala','Dwarka','Gujarat','pathshala'),
  ('Govardhan Peeth Ved Pathshala','Puri','Odisha','pathshala'),
  ('Jyotir Math Ved Pathshala','Badrinath','Uttarakhand','pathshala')
) as v(name, city, state, kind)
where not exists (
  select 1 from public.institutions i
  where lower(i.name) = lower(v.name)
    and lower(coalesce(i.state,'')) = lower(coalesce(v.state,''))
);
