/// Noms de pays en français (codes ISO 3166-1 alpha-2).
const countryNamesFr = <String, String>{
  'AF': 'Afghanistan', 'AL': 'Albanie', 'DZ': 'Algérie', 'AR': 'Argentine', 'AM': 'Arménie',
  'AU': 'Australie', 'AT': 'Autriche', 'AZ': 'Azerbaïdjan', 'BH': 'Bahreïn', 'BY': 'Biélorussie',
  'BE': 'Belgique', 'BO': 'Bolivie', 'BA': 'Bosnie-Herzégovine', 'BR': 'Brésil', 'BG': 'Bulgarie',
  'CM': 'Cameroun', 'CA': 'Canada', 'CL': 'Chili', 'CN': 'Chine', 'CO': 'Colombie',
  'CD': 'RD Congo', 'CG': 'Congo', 'KR': 'Corée du Sud', 'CR': 'Costa Rica', 'HR': 'Croatie',
  'CU': 'Cuba', 'CY': 'Chypre', 'CZ': 'Tchéquie', 'DK': 'Danemark', 'DO': 'République dominicaine',
  'EC': 'Équateur', 'EG': 'Égypte', 'GB': 'Royaume-Uni', 'EE': 'Estonie', 'FI': 'Finlande',
  'FR': 'France', 'GE': 'Géorgie', 'DE': 'Allemagne', 'GH': 'Ghana', 'GR': 'Grèce',
  'GT': 'Guatemala', 'HT': 'Haïti', 'HN': 'Honduras', 'HU': 'Hongrie', 'IS': 'Islande',
  'IN': 'Inde', 'ID': 'Indonésie', 'IR': 'Iran', 'IQ': 'Irak', 'IE': 'Irlande', 'IL': 'Israël',
  'IT': 'Italie', 'JM': 'Jamaïque', 'JP': 'Japon', 'JO': 'Jordanie', 'KZ': 'Kazakhstan',
  'KE': 'Kenya', 'XK': 'Kosovo', 'KG': 'Kirghizistan', 'LV': 'Lettonie', 'LB': 'Liban',
  'LT': 'Lituanie', 'LU': 'Luxembourg', 'MK': 'Macédoine du Nord', 'MY': 'Malaisie', 'MT': 'Malte',
  'MX': 'Mexique', 'MD': 'Moldavie', 'MN': 'Mongolie', 'ME': 'Monténégro', 'MA': 'Maroc',
  'NL': 'Pays-Bas', 'NZ': 'Nouvelle-Zélande', 'NI': 'Nicaragua', 'NG': 'Nigeria', 'NO': 'Norvège',
  'PK': 'Pakistan', 'PA': 'Panama', 'PY': 'Paraguay', 'PE': 'Pérou', 'PH': 'Philippines',
  'PL': 'Pologne', 'PT': 'Portugal', 'PR': 'Porto Rico', 'RO': 'Roumanie', 'RU': 'Russie',
  'WS': 'Samoa', 'SA': 'Arabie saoudite', 'SN': 'Sénégal', 'RS': 'Serbie', 'SG': 'Singapour',
  'SK': 'Slovaquie', 'SI': 'Slovénie', 'ZA': 'Afrique du Sud', 'ES': 'Espagne', 'SE': 'Suède',
  'CH': 'Suisse', 'SY': 'Syrie', 'TW': 'Taïwan', 'TJ': 'Tadjikistan', 'TH': 'Thaïlande',
  'TN': 'Tunisie', 'TR': 'Turquie', 'TM': 'Turkménistan', 'UG': 'Ouganda', 'UA': 'Ukraine',
  'AE': 'Émirats arabes unis', 'US': 'États-Unis', 'UY': 'Uruguay', 'UZ': 'Ouzbékistan',
  'VE': 'Venezuela', 'VN': 'Viêt Nam', 'ZW': 'Zimbabwe', 'TO': 'Tonga', 'FJ': 'Fidji', 'SR': 'Suriname',
  'CV': 'Cap-Vert', 'AO': 'Angola', 'CI': "Côte d'Ivoire", 'ET': 'Éthiopie', 'TT': 'Trinité-et-Tobago',
};

String countryName(String? iso) => iso == null ? 'Pays inconnu' : (countryNamesFr[iso] ?? iso);
