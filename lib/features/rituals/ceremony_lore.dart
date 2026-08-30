import '../../models/ritual.dart';

/// Editorial content for the ceremony detail pages.
///
/// The `rituals` table carries only identifiers and scheduling metadata, so the
/// descriptive material lives here in code where it can be reviewed in a pull
/// request. Keyed by [Ritual.slug]; anything unmatched falls back to
/// [loreFor], which builds a generic entry from the ritual itself.
///
/// Scripture citations are deliberately conservative. A precise chapter and
/// verse is given only where the attribution is well established; everything
/// else is labelled as a traditional invocation rather than dressed up with a
/// reference that cannot be stood behind.
class CeremonyLore {
  const CeremonyLore({
    required this.tagline,
    required this.why,
    required this.history,
    required this.quote,
    required this.transliteration,
    required this.meaning,
    required this.source,
    this.steps = const <String>[],
    this.facts = const <String>[],
  });

  /// One line shown under the ceremony name in the header.
  final String tagline;

  /// Why the ceremony is performed.
  final String why;

  /// Historical and textual background.
  final String history;

  /// A verse in Devanagari.
  final String quote;

  /// Roman transliteration of [quote].
  final String transliteration;

  /// Plain English sense of [quote].
  final String meaning;

  /// Where [quote] comes from.
  final String source;

  /// What usually happens, in order.
  final List<String> steps;

  /// Short practical notes.
  final List<String> facts;
}

/// Lore for every ritual currently seeded in the database, keyed by slug.
const Map<String, CeremonyLore> ceremonyLore = <String, CeremonyLore>{
  'annaprashana': CeremonyLore(
    tagline: 'The first solid food',
    why: 'Annaprashana is the first feeding of solid food, usually rice cooked with ghee, around the sixth month. It is a genuine milestone dressed as a ceremony - the child leaves total dependence on the mother and begins to take from the earth. The prayers are for good digestion, good appetite and a healthy relationship with food for life.',
    history: 'The rite is named in the Grihya Sutras and echoes the Taittiriya Upanishad, where the sage Bhrigu concludes after long meditation that food itself is Brahman. Hindu tradition treats eating as a sacrament, not a chore.',
    quote: 'अन्नं न निन्द्यात्। तद् व्रतम्।',
    transliteration: 'Annam na nindyat. Tad vratam.',
    meaning: 'Let no one speak ill of food. That is the vow.',
    source: 'Taittiriya Upanishad, Bhrigu Valli',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'The kheer or payasam offered to the deity first',
      'The first spoonful given by the maternal uncle or grandfather',
      'The tray of objects the child is invited to choose from',
    ],
    facts: const <String>[
      'Usually in the sixth month for boys and the fifth or seventh for girls, by family custom',
      'The choosing tray - a coin, a pen, a book, a clod of earth - is a much loved folk addition',
    ],
  ),
  'antyeshti': CeremonyLore(
    tagline: 'The last rites',
    why: 'Antyeshti is the final samskara, performed with the same care as the first. The body is returned to the elements through fire and the family is guided through the days that follow so that grief has a shape, a sequence and an end. Its purpose is as much for the living as for the departed.',
    history: 'The rites are set out in the Grihya and Pitrimedha Sutras and shaped by the Garuda Purana. The Isha Upanishad verse recited at cremation is among the oldest funerary texts in continuous use.',
    quote: 'वायुरनिलममृतमथेदं भस्मान्तं शरीरम्',
    transliteration: 'Vayur anilam amritam athedam bhasmantam shariram',
    meaning: 'Let this breath return to the immortal air; this body ends in ashes.',
    source: 'Isha Upanishad 17',
    steps: const <String>[
      'Preparation and final bath of the body',
      'Mukhagni and the cremation rites',
      'Asthi sanchayan and visarjan',
      'Shraddha and pinda daan on the appointed days',
    ],
    facts: const <String>[
      'Listed on the app so families can find a purohit, though it is not posted as a job',
      'The thirteen day sequence gives mourning a defined arc',
    ],
  ),
  'bhagwat-katha': CeremonyLore(
    tagline: 'Seven days with the Bhagavata',
    why: 'Bhagwat Katha is the traditional seven day telling of the Srimad Bhagavatam by a kathavachak, covering creation, the avataras and above all the life of Krishna. It is part scripture, part performance and part community gathering, and families sponsor it in thanksgiving, in memory of someone who has died, or simply to bring a neighbourhood together.',
    history: 'The seven day format, the saptah, is described within the Bhagavata Mahatmya itself. The tradition of public katha performance did much to carry devotional Hinduism to people who could not read Sanskrit.',
    quote: 'निगमकल्पतरोर्गलितं फलं शुकमुखादमृतद्रवसंयुतम्',
    transliteration: 'Nigama kalpataror galitam phalam shukamukhad amrita drava samyutam',
    meaning: 'The ripened fruit of the wish tree of the Vedas, made nectar by the mouth of Shuka.',
    source: 'Bhagavata Purana 1.1.3',
    steps: const <String>[
      'Kalash sthapana and puja of the text',
      'Daily katha across the seven days',
      'Krishna Janmotsav on the appointed day',
      'Purnahuti, aarti and bhandara',
    ],
    facts: const <String>[
      'The classic form runs seven days, the saptah',
      'The birth of Krishna is celebrated as a highlight mid week',
    ],
  ),
  'bhoomi-pujan': CeremonyLore(
    tagline: 'Asking the earth before you build',
    why: 'Bhoomi Pujan is performed before construction begins. The family apologises to the earth for the digging about to be done, honours the serpent held to bear the land and lays the first brick or foundation stone with mantras. Before anything is taken from a place, something is offered to it.',
    history: 'The custom is rooted in the Vastu tradition and the Vastu Purusha legend, and remains near universal in India - performed for village houses and for national infrastructure projects alike.',
    quote: 'समुद्रवसने देवि पर्वतस्तनमण्डले। विष्णुपत्नि नमस्तुभ्यं पादस्पर्शं क्षमस्व मे।',
    transliteration: 'Samudravasane devi parvatastanamandale, vishnupatni namastubhyam padasparsham kshamasva me',
    meaning: 'Goddess robed in the ocean, breasted with mountains, consort of Vishnu - forgive me the touch of my feet.',
    source: 'Traditional prayer to the Earth',
    steps: const <String>[
      'Sankalpa and Ganesh puja at the site',
      'Puja of Bhoomi Devi and the naga',
      'Digging of the foundation pit at the chosen corner',
      'Laying of the first brick with the kalash',
    ],
    facts: const <String>[
      'The first dig is traditionally made in the north east corner',
      'A kalash, coins and a silver naga are often placed in the foundation',
    ],
  ),
  'chudakarana': CeremonyLore(
    tagline: 'Mundan, the first haircut',
    why: 'Chudakarana is the ceremonial shaving of the head, usually in the first or third year. Hair grown in the womb is offered up and the head is cleaned, cooled and blessed. Practically it was always sound care for an infant in a hot country; ritually it is a letting go of what was carried from before, so the child begins on its own.',
    history: 'Prescribed in the Grihya Sutras and still one of the most widely observed samskaras in India, often performed at a family temple or a pilgrimage site to which the hair is offered.',
    quote: 'ओं आयुष्मान् भव वर्चस्वी भव',
    transliteration: 'Om ayushman bhava varchasvi bhava',
    meaning: 'Be long lived, be full of lustre.',
    source: 'Grihya Sutra, blessing formula',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'Havan with the child in the lap of the mother or maternal uncle',
      'The first lock cut by the priest, the rest by the barber',
      'Bath, new clothes and blessings',
    ],
    facts: const <String>[
      'Called mundan across most of north India',
      'Often vowed to a temple, where the hair is offered',
    ],
  ),
  'durga-saptashati': CeremonyLore(
    tagline: 'Seven hundred verses to the Goddess',
    why: 'Durga Saptashati, also called Chandi Path, is the recitation of seven hundred verses describing the Goddess victory over Mahishasura and other demons. It is read for protection, for strength in adversity and especially during Navratri. The text is unusual in placing supreme divinity in a feminine form without qualification.',
    history: 'It forms part of the Markandeya Purana and is one of the earliest complete statements of Shakta theology. Its most quoted verses, the Ya Devi sequence, identify the Goddess with the qualities present in every being.',
    quote: 'या देवी सर्वभूतेषु शक्तिरूपेण संस्थिता। नमस्तस्यै नमस्तस्यै नमस्तस्यै नमो नमः।',
    transliteration: 'Ya devi sarvabhuteshu shaktirupena samsthita, namas tasyai namas tasyai namas tasyai namo namah',
    meaning: 'To the Goddess who abides in all beings as power - salutations, salutations, salutations again and again.',
    source: 'Devi Mahatmya, Durga Saptashati',
    steps: const <String>[
      'Kalash sthapana and Ganesh puja',
      'Recitation of the kavach, argala and kilaka',
      'The thirteen chapters of the Saptashati',
      'Havan, kanya pujan and aarti',
    ],
    facts: const <String>[
      'Most often recited through the nine nights of Navratri',
      'Part of the Markandeya Purana',
    ],
  ),
  'ganesh-puja': CeremonyLore(
    tagline: 'Remover of obstacles, invoked first',
    why: 'Ganesh Puja is the opening of almost every Hindu rite and is also performed on its own before a venture, an examination, a new business or a move. Ganesha is invoked first because he is the lord of beginnings and of obstacles, both their placing and their removal, and because starting well is held to matter more than starting fast.',
    history: 'The convention of invoking Ganesha before all other deities was firmly established by the Puranic period, and the Ganapati Atharvashirsha gives him an independent theological standing. Ganesh Chaturthi became a mass public festival in the late nineteenth century.',
    quote: 'वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ। निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा।',
    transliteration: 'Vakratunda mahakaya suryakoti samaprabha, nirvighnam kuru me deva sarvakaryeshu sarvada',
    meaning: 'Curved trunk, mighty form, radiance of a million suns - make my every undertaking free of obstacles, always.',
    source: 'Traditional Ganesha dhyana shloka',
    steps: const <String>[
      'Sankalpa and installation of the murti',
      'Shodashopachara - the sixteen offerings',
      'Recitation of the Ganapati Atharvashirsha or 108 names',
      'Modak offering and aarti',
    ],
    facts: const <String>[
      'Performed at the start of nearly every other ceremony',
      'Durva grass and modak are the classic offerings',
    ],
  ),
  'garbhadhana': CeremonyLore(
    tagline: 'The first of the sixteen samskaras',
    why: 'Garbhadhana is the sanskar of conception. It treats the decision to become parents as a deliberate, sacred act rather than an accident of circumstance, and asks the couple to enter parenthood with a settled mind, good health and a shared intention. The prayers are for a healthy child and for the parents to be worthy of raising one.',
    history: 'It is described in the Grihya Sutras, the household manuals attached to each Veda, which lay out the domestic rites of a married householder. Later digests such as the Manusmriti place it first in the sequence of samskaras that shape a life from before birth to after death.',
    quote: 'ओं प्रजापते न त्वदेतान्यन्यो विश्वा जातानि परि ता बभूव',
    transliteration: 'Om prajapate na tvadetany anyo vishva jatani pari ta babhuva',
    meaning: 'Lord of creatures, none but you encompasses all these born beings.',
    source: 'Rigveda, Prajapati Sukta',
    steps: const <String>[
      'Sankalpa - the couple states the intention aloud',
      'Ganesh puja and punyahavachan to purify the space',
      'Havan with prayers for a healthy conception',
      'Blessings from elders present',
    ],
    facts: const <String>[
      'Performed privately, usually with only immediate family present',
      'Often folded into the post-wedding rites in modern practice',
    ],
  ),
  'griha-pravesh': CeremonyLore(
    tagline: 'Entering a new home for the first time',
    why: 'Griha Pravesh is performed before a family begins living in a new house. The house is cleaned, the threshold marked, milk boiled until it rises over the vessel and a havan lit so that the first fire in the home is a sacred one. It turns a building into a household and asks that whatever happens inside these walls be peaceful.',
    history: 'The Rigveda contains a hymn to Vastoshpati, the lord of the dwelling, asking him to recognise the residents and be kind to them - one of the earliest surviving house blessings in any language. The rite has been performed in essentially this form for millennia.',
    quote: 'वास्तोष्पते प्रति जानीह्यस्मान् स्वावेशो अनमीवो भवा नः',
    transliteration: 'Vastoshpate prati janihy asman svavesho anamivo bhava nah',
    meaning: 'Lord of the dwelling, know us; be a good home to us, free of sickness.',
    source: 'Rigveda 7.54.1, Vastoshpati Sukta',
    steps: const <String>[
      'Threshold puja and breaking of the coconut',
      'Kalash sthapana and Ganesh puja',
      'Vastu shanti havan',
      'Boiling of milk in the new kitchen and the first meal cooked',
    ],
    facts: const <String>[
      'The milk is allowed to boil over deliberately, as a sign of abundance',
      'Usually timed to an auspicious muhurat, avoiding certain months',
    ],
  ),
  'jatakarma': CeremonyLore(
    tagline: 'The welcome given to a newborn',
    why: 'Jatakarma is performed as soon after birth as is practical. Honey and ghee are touched to the infant lips while the father whispers prayers for intellect and long life into the ear. It is the moment a family formally receives a child into itself, before any name, any horoscope, any expectation.',
    history: 'The rite is set out in the Grihya Sutras with unusual precision, including the words the father speaks into the child ear. It is one of the oldest attested birth rites still performed in Indian households.',
    quote: 'ओं मेधां ते देवः सविता दधातु',
    transliteration: 'Om medham te devah savita dadhatu',
    meaning: 'May the radiant Savitr place intelligence in you.',
    source: 'Grihya Sutra, Medhajanana mantra',
    steps: const <String>[
      'Honey and ghee touched to the infant lips',
      'Medhajanana - the whispered prayer for intellect',
      'Ayushya mantras for long life',
      'Brief havan where the family wishes',
    ],
    facts: const <String>[
      'Traditionally performed before the umbilical cord is cut',
      'Often combined with Namakarana in modern practice',
    ],
  ),
  'jyotishacharya': CeremonyLore(
    tagline: 'Purohits qualified in jyotisha',
    why: 'This listing marks purohits qualified in jyotisha - horoscope reading, muhurat selection and the remedial rites that follow from a chart. Families consult them to fix an auspicious time for a wedding or a griha pravesh, or to understand a difficult period.',
    history: 'Jyotisha is one of the six Vedangas, the auxiliary disciplines of the Veda, and was developed originally to fix the correct time for sacrifices. Its classical texts include the Brihat Parashara Hora Shastra and the Brihat Samhita of Varahamihira.',
    quote: 'कालोऽस्मि लोकक्षयकृत् प्रवृद्धो',
    transliteration: 'Kalo smi lokakshayakrit pravriddho',
    meaning: 'I am time, grown mighty, the destroyer of worlds.',
    source: 'Bhagavad Gita 11.32',
    steps: const <String>[],
    facts: const <String>[
      'A specialisation shown on purohit profiles',
      'Jyotisha is one of the six Vedangas',
    ],
  ),
  'karmakandi': CeremonyLore(
    tagline: 'Purohits who perform the ritual sequences',
    why: 'This listing marks purohits specialising in karmakanda - the practical performance of havan, samskaras and shanti rites, with the materials, sequence and timing done correctly. It is the everyday craft of the profession and the qualification most families are actually looking for.',
    history: 'Karmakanda is the ritual portion of the Veda, distinguished in the tradition from jnanakanda, the portion concerned with knowledge. The Kalpa Sutras are its manuals.',
    quote: 'यज्ञेन यज्ञमयजन्त देवाः',
    transliteration: 'Yajnena yajnam ayajanta devah',
    meaning: 'By sacrifice the gods worshipped sacrifice itself.',
    source: 'Rigveda 10.90.16, Purusha Sukta',
    steps: const <String>[],
    facts: const <String>[
      'A specialisation shown on purohit profiles',
      'Covers the day to day ritual work of a purohit',
    ],
  ),
  'karnavedha': CeremonyLore(
    tagline: 'Ear piercing',
    why: 'Karnavedha is the piercing of the ear lobes, done for both boys and girls in the first years. Tradition attaches protective and health value to it and it also marks the child as belonging to a family and its customs. It is short, done with care and followed by comforting and sweets.',
    history: 'Ear piercing is discussed in the Sushruta Samhita, the classical surgical compendium, which describes technique, the right age and how to avoid injury - a reminder that these rites were often practical medicine given ceremonial form.',
    quote: 'ओं भद्रं कर्णेभिः शृणुयाम देवाः',
    transliteration: 'Om bhadram karnebhih shrinuyama devah',
    meaning: 'O gods, may we hear what is auspicious with our ears.',
    source: 'Rigveda, Svasti Sukta',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'The child seated facing east on a lap',
      'Right ear pierced first, then the left',
      'Turmeric applied, blessings and sweets',
    ],
    facts: const <String>[
      'Often performed on the same day as Chudakarana',
      'Sushruta Samhita discusses the correct method and age',
    ],
  ),
  'kathavachak': CeremonyLore(
    tagline: 'Purohits who narrate katha',
    why: 'This listing marks purohits who perform katha - the sustained narration of the Bhagavatam, the Ramayana or the Puranas before an audience. It is a distinct skill from ritual performance, closer to teaching and storytelling, and a good kathavachak can hold a gathering for hours across many days.',
    history: 'The katha tradition carried scripture to audiences who could not read Sanskrit and shaped devotional life across India for centuries, producing its own conventions of music, humour and digression alongside the text.',
    quote: 'श्रवणं कीर्तनं विष्णोः स्मरणं पादसेवनम्',
    transliteration: 'Shravanam kirtanam vishnoh smaranam padasevanam',
    meaning: 'Hearing, singing and remembering the Lord, and serving at his feet.',
    source: 'Bhagavata Purana 7.5.23',
    steps: const <String>[],
    facts: const <String>[
      'A specialisation shown on purohit profiles',
      'Distinct from ritual performance',
    ],
  ),
  'keshanta': CeremonyLore(
    tagline: 'The first shave, the threshold of adulthood',
    why: 'Keshanta is the first shaving of the beard, around the sixteenth year. It is a quiet acknowledgement that a boy has become a young man, with a renewal of the vows of study and self restraint that came with initiation. Where modern life has no marker for this passage, the tradition made one deliberately.',
    history: 'The Grihya Sutras place it around age sixteen and pair it with a fresh commitment to brahmacharya, so that the physical sign of adulthood arrives together with an ethical one.',
    quote: 'ओं तेजोऽसि तेजो मयि धेहि',
    transliteration: 'Om tejo si tejo mayi dhehi',
    meaning: 'You are radiance; place radiance in me.',
    source: 'Yajurveda, invocation of splendour',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'Havan for strength and clarity',
      'The ceremonial first shave',
      'Renewal of the vows of the student',
    ],
    facts: const <String>[
      'Also called Godana',
      'Traditionally in the sixteenth year',
    ],
  ),
  'mahamrityunjaya': CeremonyLore(
    tagline: 'The great victory over death',
    why: 'Mahamrityunjaya Jaap is undertaken during serious illness, after an accident or at a time of real fear for a life. The mantra is repeated in fixed counts, often eleven thousand or one hundred and twenty five thousand times, by one purohit or by several together. It is the rite families turn to when there is nothing else in their hands.',
    history: 'The mantra is a verse of the Rigveda addressed to Tryambaka, and is one of the very few Vedic verses that has remained in unbroken popular use from the Vedic age to the present day.',
    quote: 'ओं त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्।',
    transliteration: 'Om tryambakam yajamahe sugandhim pushtivardhanam, urvarukam iva bandhanan mrityor mukshiya mamritat',
    meaning: 'We worship the three eyed one, fragrant, increaser of nourishment. As a cucumber is freed from its stem, may we be freed from death, not from immortality.',
    source: 'Rigveda 7.59.12',
    steps: const <String>[
      'Sankalpa stating the name and gotra of the person',
      'Kalash sthapana and Shiva puja',
      'The jaap in its fixed count, often by several purohits',
      'Havan of one tenth the count, then purnahuti',
    ],
    facts: const <String>[
      'Commonly done in counts of 11,000 or 1,25,000',
      'Frequently paired with a Rudrabhishek',
    ],
  ),
  'namakarana': CeremonyLore(
    tagline: 'The naming ceremony',
    why: 'Namakarana gives the child a name, usually on the eleventh or twelfth day. The name is chosen with care - by the birth star, by a family deity, by a grandparent kept in memory - because in this tradition a name is not a label but a daily invocation. Everyone who calls the child will be repeating it thousands of times.',
    history: 'Described in the Grihya Sutras and in later ritual digests, which discuss auspicious syllables and the naming conventions tied to the nakshatra of birth. The custom of a secret ritual name alongside a public one is very old.',
    quote: 'नामाखिलस्य व्यवहारहेतुः शुभावहं कर्मसु भाग्यहेतुः',
    transliteration: 'Namakhilasya vyavaharahetuh shubhavaham karmasu bhagyahetuh',
    meaning: 'A name is the ground of all dealings, a bringer of good and a cause of fortune in every act.',
    source: 'Traditional verse quoted in the Grihya tradition',
    steps: const <String>[
      'Ganesh puja and punyahavachan',
      'Havan and the sankalpa naming the child',
      'The name spoken into the child ear four times',
      'Blessings, sweets and the first cradle',
    ],
    facts: const <String>[
      'Usually on the eleventh or twelfth day after birth',
      'The nakshatra of birth often decides the first syllable',
    ],
  ),
  'navagraha-shanti': CeremonyLore(
    tagline: 'Settling the nine planets',
    why: 'Navagraha Shanti is performed when a horoscope shows a difficult planetary period, or before a major undertaking. Each of the nine grahas receives its own mantra, grain, colour and offering. Whatever one makes of the astrology, the ritual gives a family something considered and orderly to do at a time when they feel they have no control, which is not a small thing.',
    history: 'The nine grahas are systematised in classical jyotisha texts such as the Brihat Parashara Hora Shastra, and shanti rites for them appear in the Grihya Parishishtas. Navagraha shrines are standard in most large South Indian temples.',
    quote: 'ओं ब्रह्मा मुरारिस्त्रिपुरान्तकारी भानुः शशी भूमिसुतो बुधश्च',
    transliteration: 'Om brahma murarist ripurantakari bhanuh shashi bhumisuto budhashcha',
    meaning: 'Brahma, Vishnu and Shiva; Sun, Moon, Mars and Mercury - may they be favourable.',
    source: 'Traditional Navagraha Stotra',
    steps: const <String>[
      'Sankalpa and Ganesh puja',
      'Navagraha mandala drawn and the nine invoked',
      'Havan with the specific samidha of each graha',
      'Daan of the prescribed grains and cloth',
    ],
    facts: const <String>[
      'Each graha has its own grain, metal, colour and direction',
      'Often prescribed alongside a specific charitable donation',
    ],
  ),
  'nishkramana': CeremonyLore(
    tagline: 'The child first outing',
    why: 'Nishkramana is the first time the baby is taken out of the house, generally in the fourth month. The infant is shown the sun, the moon or the temple deity, and the world is formally introduced. It marks the end of the confined weeks after birth and the family stepping back into public life with a new member.',
    history: 'The Grihya Sutras prescribe it around the third or fourth month, when the child is judged strong enough for open air. The temple visit that usually accompanies it is a later, and now near universal, addition.',
    quote: 'ओं तच्चक्षुर्देवहितं पुरस्ताच्छुक्रमुच्चरत्',
    transliteration: 'Om tac chakshur devahitam purastac chukram uccharat',
    meaning: 'That eye, set by the gods, rises bright before us.',
    source: 'Yajurveda, sun invocation',
    steps: const <String>[
      'Short puja at home before leaving',
      'The child carried out and shown the sun or moon',
      'First visit to the family temple',
      'Blessings from elders and priest',
    ],
    facts: const <String>[
      'Usually in the third or fourth month',
      'Timed for early morning or evening light, never harsh midday sun',
    ],
  ),
  'pumsavana': CeremonyLore(
    tagline: 'A prayer for the health of the growing child',
    why: 'Pumsavana is performed in the third or fourth month of pregnancy. Its purpose is the wellbeing of the child in the womb and the strength of the mother carrying it. Traditionally herbal drops and a special diet accompany the mantras, and the family gathers to surround the expectant mother with calm and care at a vulnerable time.',
    history: 'The rite appears in the Grihya Sutras and in Ayurvedic literature, where the Sushruta Samhita and Charaka Samhita discuss the care of the pregnant woman month by month. The ceremony sits at the meeting point of ritual and early medicine.',
    quote: 'ओं धाता ददातु नो रयिमीशानो जगतस्पतिः',
    transliteration: 'Om dhata dadatu no rayim ishano jagataspatih',
    meaning: 'May the sustainer, lord of all that moves, grant us wellbeing.',
    source: 'Rigveda, Dhata invocation',
    steps: const <String>[
      'Sankalpa by the couple',
      'Ganesh puja and kalash sthapana',
      'Havan with mantras for the mother and child',
      'Aarti and distribution of prasad',
    ],
    facts: const <String>[
      'Usually held in the third or fourth month',
      'The mother is seated facing east through the rite',
    ],
  ),
  'ramayan-path': CeremonyLore(
    tagline: 'The whole epic, read end to end',
    why: 'Ramayan Path is the complete recitation of the Ramcharitmanas, usually over several days, sometimes unbroken through a day and night as an akhand path. Families undertake it to fulfil a vow, to mark an anniversary or to bring the household together around a shared act of attention for longer than any single evening allows.',
    history: 'Tulsidas wrote the Ramcharitmanas at Ayodhya and Varanasi in the sixteenth century. Its verses became so embedded in north Indian life that for centuries they served as a shared moral vocabulary across castes and villages.',
    quote: 'मंगल भवन अमंगल हारी। द्रवउ सो दसरथ अजिर बिहारी।',
    transliteration: 'Mangala bhavana amangala hari, dravau so dasaratha ajira bihari',
    meaning: 'Abode of good and remover of ill - may he who played in the courtyard of Dasharatha be moved to grace.',
    source: 'Ramcharitmanas, Balkand',
    steps: const <String>[
      'Ganesh puja and sthapana of the text',
      'Continuous recitation across the seven kands',
      'Bhog and aarti at the conclusion',
      'Bhandara or prasad distribution',
    ],
    facts: const <String>[
      'An akhand path runs unbroken and needs a relay of readers',
      'Commonly spread over three, seven or nine days',
    ],
  ),
  'rudrabhishek': CeremonyLore(
    tagline: 'The continuous bathing of Shiva',
    why: 'Rudrabhishek is the ceremonial bathing of the Shiva linga with milk, curd, honey, ghee, sugar and water while the Rudram is chanted. It is sought for health, for relief from long standing difficulty and for peace of mind. The unbroken stream of liquid over the linga is the visible form of an unbroken stream of attention.',
    history: 'The Sri Rudram of the Yajurveda, chanted during the abhishek, is one of the oldest and most revered liturgies in the Hindu canon, and contains the mantra Om Namah Shivaya at its centre.',
    quote: 'ओं नमः शिवाय',
    transliteration: 'Om namah shivaya',
    meaning: 'Salutations to the auspicious one.',
    source: 'Yajurveda, Sri Rudram',
    steps: const <String>[
      'Sankalpa and Ganesh puja',
      'Panchamrit abhishek of the linga',
      'Chanting of the Rudram and Chamakam',
      'Bilva patra offering and aarti',
    ],
    facts: const <String>[
      'Especially performed on Mondays and in the month of Shravan',
      'Bilva leaves are considered indispensable to the offering',
    ],
  ),
  'samavartana': CeremonyLore(
    tagline: 'Graduation, the return home',
    why: 'Samavartana marks the end of studenthood. The student bathes ceremonially, sets aside the marks of a learner and returns home ready to take up the responsibilities of a householder. It is the convocation of the Vedic system, and its logic is simple - study is not endless, it ends and then you must live what you learned.',
    history: 'Described in the Grihya Sutras, where the bath itself is the central act, giving the graduate the title snataka, one who has bathed. The teacher final address to the student in the Taittiriya Upanishad is the best known graduation speech in Indian literature.',
    quote: 'सत्यं वद। धर्मं चर। स्वाध्यायान्मा प्रमदः।',
    transliteration: 'Satyam vada. Dharmam chara. Svadhyayan ma pramadah.',
    meaning: 'Speak the truth. Walk in dharma. Do not neglect your study.',
    source: 'Taittiriya Upanishad, Shikshavalli',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'The ceremonial snana with scented water',
      'New clothes, garland and ornaments',
      'Final instruction from the teacher and guru dakshina',
    ],
    facts: const <String>[
      'The graduate is thereafter called a snataka',
      'Traditionally the last rite before marriage was considered',
    ],
  ),
  'satyanarayan': CeremonyLore(
    tagline: 'The vow of the true Lord',
    why: 'Satyanarayan Puja is performed in thanksgiving - for a new job, a recovery, a wedding, a safe return - or simply to steady a household. Its distinctive feature is the katha, five short stories read aloud, each about someone who promised the puja and what followed when they kept or broke that promise. The theme throughout is that truth kept is its own protection.',
    history: 'The katha comes from the Reva Khanda of the Skanda Purana. The puja spread widely because it needs no elaborate materials and no special caste qualification to attend, which made it one of the most democratic rites in popular Hinduism.',
    quote: 'सत्यं परं धीमहि',
    transliteration: 'Satyam param dhimahi',
    meaning: 'We meditate upon the supreme truth.',
    source: 'Bhagavata Purana 1.1.1',
    steps: const <String>[
      'Kalash sthapana and Ganesh puja',
      'Invocation of Satyanarayana and the navagraha',
      'Reading of the five chapters of the katha',
      'Aarti and distribution of the sinni prasad',
    ],
    facts: const <String>[
      'Traditionally on a purnima or a sankranti day',
      'The prasad of banana, wheat flour and sugar is part of the vow itself',
    ],
  ),
  'simantonnayana': CeremonyLore(
    tagline: 'The parting of the hair, a blessing for mother and child',
    why: 'Simantonnayana is the baby shower of the Vedic tradition, held in the later months of pregnancy. The husband parts the wife hair with a symbolic comb while mantras are recited. Beyond the ritual, its real work is emotional - the family openly wishes the mother courage and cheer, and she is given rest, sweets and attention before the birth.',
    history: 'Named in the Grihya Sutras and elaborated in the smriti literature, it survives across India as godh bharai, seemantham and valaikappu, with local customs layered on the same Vedic core.',
    quote: 'यत्र नार्यस्तु पूज्यन्ते रमन्ते तत्र देवताः',
    transliteration: 'Yatra naryastu pujyante ramante tatra devatah',
    meaning: 'Where women are honoured, there the gods rejoice.',
    source: 'Manusmriti 3.56',
    steps: const <String>[
      'Sankalpa and Ganesh puja',
      'Havan for the mother and the unborn child',
      'The symbolic parting of the hair',
      'Bangles, sweets and blessings from the women of the family',
    ],
    facts: const <String>[
      'Known as godh bharai in the north and seemantham in the south',
      'Held in the fifth, seventh or eighth month depending on family custom',
    ],
  ),
  'sunderkand': CeremonyLore(
    tagline: 'The most loved chapter of the Ramayana',
    why: 'Sunderkand Paath is the recitation of the fifth book of the Ramcharitmanas, the one in which Hanuman crosses the ocean, finds Sita and returns with hope. Families read it for courage, for the removal of fear and when someone is struggling. It is the only section of the epic in which the mission succeeds from start to finish, which is exactly why people turn to it.',
    history: 'Tulsidas composed the Ramcharitmanas in Awadhi in the sixteenth century, deliberately in the language people spoke, and Sunderkand became the section most often read on its own in household gatherings.',
    quote: 'बुद्धिर्बलं यशो धैर्यं निर्भयत्वमरोगता। अजाड्यं वाक्पटुत्वं च हनुमत्स्मरणाद्भवेत्।',
    transliteration: 'Buddhir balam yasho dhairyam nirbhayatvam arogata, ajadyam vakpatutvam cha hanumat smaranad bhavet',
    meaning: 'Intelligence, strength, fame, courage, fearlessness, health, alertness and eloquence come from remembering Hanuman.',
    source: 'Traditional Hanuman stotra',
    steps: const <String>[
      'Ganesh puja and Hanuman sthapana',
      'Continuous recitation of the Sunderkand',
      'Hanuman Chalisa and aarti',
      'Prasad of boondi or laddu',
    ],
    facts: const <String>[
      'Most often read on a Tuesday or Saturday',
      'Takes roughly three hours read at a steady pace',
    ],
  ),
  'upanayana': CeremonyLore(
    tagline: 'The sacred thread, the second birth',
    why: 'Upanayana is the initiation into formal study. The student receives the yajnopavita, is taught the Gayatri mantra and accepts the discipline of a learner. It is called the second birth because the tradition holds that a person is born once from parents and again from a teacher, and that the second birth is the one you must earn.',
    history: 'The rite is described across the Grihya Sutras and the Dharma Sutras, which specify the age, the staff, the deerskin and the girdle for each varna. Historically it opened the years of formal Vedic education under a guru.',
    quote: 'ओं भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि। धियो यो नः प्रचोदयात्।',
    transliteration: 'Om bhur bhuvah svah tat savitur varenyam bhargo devasya dhimahi dhiyo yo nah prachodayat',
    meaning: 'We meditate on the adorable radiance of the divine Savitr; may it inspire our understanding.',
    source: 'Rigveda 3.62.10, the Gayatri mantra',
    steps: const <String>[
      'Ganesh puja, punyahavachan and havan',
      'The yajnopavita worn for the first time',
      'The Gayatri mantra taught by the father or acharya',
      'Bhiksha - the symbolic first alms from elders',
    ],
    facts: const <String>[
      'Called janeu, munja or brahmopadesham regionally',
      'The Gayatri mantra is given here and recited daily thereafter',
    ],
  ),
  'vastu-puja': CeremonyLore(
    tagline: 'Peace for the space you live in',
    why: 'Vastu Puja addresses the dwelling itself rather than the people in it. Where construction has gone against traditional guidance, or where a family feels persistently unsettled, the rite makes an offering to the presiding spirit of the site and asks for harmony without demanding that walls be torn down. It is a way of making peace with a place.',
    history: 'Vastu shastra is developed in texts such as the Mayamatam and Manasara, and the underlying Vastu Purusha legend explains why the plot itself is honoured before anything is built upon it.',
    quote: 'ओं वास्तोष्पते शग्मया संसदा ते सक्षीमहि',
    transliteration: 'Om vastoshpate shagmaya samsada te sakshimahi',
    meaning: 'Lord of the dwelling, may we prosper in your kindly company.',
    source: 'Rigveda, Vastoshpati Sukta',
    steps: const <String>[
      'Sankalpa and Ganesh puja',
      'Kalash sthapana at the appropriate corner',
      'Vastu havan and offerings to the dikpalas',
      'Aarti and sprinkling of the consecrated water through the house',
    ],
    facts: const <String>[
      'Often performed without any structural change to the building',
      'Commonly combined with Griha Pravesh',
    ],
  ),
  'vedarambha': CeremonyLore(
    tagline: 'The start of scriptural study',
    why: 'Vedarambha marks the beginning of study of the Vedas themselves, after initiation has been given. Teacher and student sit together, invoke the same prayer for protection and ask to be free of friction between them. It is the formal opening of a relationship that in the old system would shape the next decade of a life.',
    history: 'The rite is recognised in the Grihya tradition as distinct from Upanayana, though many families now perform them together. The shanti mantra recited is the opening invocation of the Taittiriya and Katha Upanishads.',
    quote: 'ओं सह नाववतु। सह नौ भुनक्तु। सह वीर्यं करवावहै।',
    transliteration: 'Om saha navavatu, saha nau bhunaktu, saha viryam karavavahai',
    meaning: 'May we be protected together, nourished together, and work with vigour together.',
    source: 'Taittiriya Upanishad, Shanti Mantra',
    steps: const <String>[
      'Ganesh puja and sankalpa',
      'Havan invoking Saraswati and Brihaspati',
      'The first verses recited with the teacher',
      'Guru dakshina offered',
    ],
    facts: const <String>[
      'Often merged with Upanayana in modern practice',
      'The shanti mantra asks teacher and student to be free of ill will',
    ],
  ),
  'vedic-knowledge': CeremonyLore(
    tagline: 'Purohits trained in Vedic recitation',
    why: 'This listing marks purohits with formal training in Vedic recitation and ritual grammar - the shakha they have learnt, the accents they maintain and the sequences they can perform from memory. Families who want a rite performed strictly by the book look for this qualification.',
    history: 'Vedic recitation has been transmitted orally with extraordinary accuracy for thousands of years through patha techniques such as jata and ghana. UNESCO recognised the tradition of Vedic chanting as intangible cultural heritage.',
    quote: 'ओं शं नो मित्रः शं वरुणः',
    transliteration: 'Om sham no mitrah sham varunah',
    meaning: 'May Mitra be kind to us, may Varuna be kind to us.',
    source: 'Taittiriya Upanishad, Shanti Mantra',
    steps: const <String>[],
    facts: const <String>[
      'A specialisation shown on purohit profiles',
      'Not something a family posts as a job',
    ],
  ),
  'vidyarambha': CeremonyLore(
    tagline: 'The beginning of learning',
    why: 'Vidyarambha is the child first formal lesson. The first letters are traced in rice or sand, often guided by an elder hand, and Saraswati and Ganesha are invoked. It exists to make the start of education a joyful, sanctified thing rather than an administrative one, so that learning is associated from day one with reverence and delight.',
    history: 'The rite grew in prominence in the medieval period and is especially strong in Kerala and coastal Karnataka, where Vidyarambham on Vijayadashami draws very large gatherings. The underlying idea - that knowledge is a deity, not a commodity - is much older.',
    quote: 'असतो मा सद्गमय। तमसो मा ज्योतिर्गमय।',
    transliteration: 'Asato ma sadgamaya, tamaso ma jyotirgamaya',
    meaning: 'Lead me from the unreal to the real, from darkness to light.',
    source: 'Brihadaranyaka Upanishad 1.3.28',
    steps: const <String>[
      'Ganesh and Saraswati puja',
      'The first letters written in rice or sand',
      'The child recites after the elder',
      'Books and a pen offered at the altar',
    ],
    facts: const <String>[
      'Widely performed on Vijayadashami',
      'Usually between the ages of two and five',
    ],
  ),
  'vivaha': CeremonyLore(
    tagline: 'Marriage, the great samskara',
    why: 'Vivaha binds two people and two families through the fire as witness. The seven steps of the saptapadi are the legal and spiritual heart of it - with each step the couple names something they will build together, from nourishment to strength to friendship. Everything else, however lavish, is arranged around those seven steps.',
    history: 'The wedding hymn of the Rigveda, the Surya Sukta, is among the oldest marriage liturgies still in use anywhere in the world, and phrases from it are recited at Hindu weddings today. Indian law recognises the saptapadi as the point at which a Hindu marriage is complete.',
    quote: 'धर्मेच अर्थेच कामेच नातिचरामि',
    transliteration: 'Dharmecha arthecha kamecha naticharami',
    meaning: 'In dharma, in prosperity and in pleasure, I shall not transgress against you.',
    source: 'Traditional saptapadi vow',
    steps: const <String>[
      'Ganesh puja, mandap sthapana and kalash',
      'Kanyadaan and panigrahan',
      'Vivaha havan and the saptapadi',
      'Sindoor, mangalsutra and blessings from elders',
    ],
    facts: const <String>[
      'The saptapadi is what completes the marriage in Hindu law',
      'The Rigveda wedding hymn is still recited in part today',
    ],
  ),
};

/// Returns the lore for [ritual], or a generic entry when the slug is unknown.
///
/// New rows can be added to the `rituals` table without shipping an app update;
/// they simply show the generic copy until lore is written for them.
CeremonyLore loreFor(Ritual ritual) {
  final match = ceremonyLore[ritual.slug];
  if (match != null) return match;
  final name = ritual.name;
  return CeremonyLore(
    tagline: 'A ceremony performed with a purohit',
    why:
        '$name is performed with the guidance of a purohit, who recites the '
        'appropriate mantras and arranges the offerings in the order the '
        'tradition prescribes. Families hold it to mark a passage, to give '
        'thanks or to ask for peace at a particular moment in their lives.',
    history:
        'The rites of Hindu households are set out in the Grihya Sutras and '
        'elaborated in the smriti and Puranic literature, with regional custom '
        'layered on top over many centuries. Your purohit can explain how '
        '$name is kept in your own family tradition.',
    quote: '\u0913\u0902 \u0938\u0930\u094d\u0935\u0947 \u092d\u0935\u0928\u094d\u0924\u0941 \u0938\u0941\u0916\u093f\u0928\u0903 \u0938\u0930\u094d\u0935\u0947 \u0938\u0928\u094d\u0924\u0941 \u0928\u093f\u0930\u093e\u092e\u092f\u093e\u0903',
    transliteration: 'Om sarve bhavantu sukhinah sarve santu niramayah',
    meaning: 'May all be happy, may all be free from illness.',
    source: 'Traditional shanti prayer',
    facts: const <String>[
      'Speak to your purohit about the materials to arrange beforehand',
      'Timing is usually chosen by an auspicious muhurat',
    ],
  );
}
