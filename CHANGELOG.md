# Versions d'Octogone

Chaque version publiée a sa release GitHub avec les APK Android (`scripts/release_android.sh`).
Le texte d'une section sert de notes à la release correspondante.

## 0.4.0

Combat contre l'IA (phase 4)
- Nouvel onglet Combat avec quatre modes : Combat rapide, Soirée (5 de tes cartes, le 5e combat en main event de 5 rounds), Route vers la ceinture (les vrais classés UFC de ta catégorie, du n°15 au champion ; une défaite et tu repars du début) et Scénarios (les vraies rivalités de la base à rejouer, avec le vrai bilan).
- Combat tactique au tour par tour : à chaque échange, toi et l'IA choisissez une action en secret (frappes, coup de pied, takedown, clinch, garde, esquive, ground and pound, soumission, se relever, contrôle), puis révélation simultanée. Ta main de 4 cartes dépend du profil du combattant : un frappeur reçoit plus de coups, un lutteur plus de takedowns.
- Choix avant le combat : niveau de l'IA (facile, normal, difficile, qui apprend tes habitudes), format court ou complet, même catégorie ou poids libre, commandes en cartes ou en roue.
- Arène animée : face-à-face avec les photos de la rareté jouée, jauges de santé, d'endurance et de momentum, coups signature dès l'Épique, knockdowns, arrêts de l'arbitre, commentaires, sons de combat et vibrations. Minuteur de 15 s optionnel dans les Réglages.
- Mini-jeux de soumission : viser la zone au bon moment pour attaquer, taper le plus vite possible pour se dégager.
- Fin de combat : KO, KO technique, soumission ou décision des 3 juges, avec leurs cartes de pointage.
- Équilibrage vérifié sur 10 000 combats simulés : environ 35 % de KO, 20 % de soumissions, 43 % de décisions ; aucun style ne domine, la rareté aide sans garantir la victoire.

Cartes Tactique
- Nouvelle famille de cartes : 8 bonus de combat (Second souffle, Coin du coach, Foule en délire, Mâchoire d'acier, Instinct de tueur, Sortie de crise, Plan de match, Pression totale), de Commune à Légendaire, plus forts selon la rareté. 2 au plus par combat, une fois chacune ; la carte reste dans ta collection.
- Une carte Tactique en plus dans chaque booster (7 cartes en Standard, 11 en Premium), 3 cartes offertes à chaque joueur, fabricables à l'Atelier.

Récompenses
- Chaque combat est vérifié par le serveur avant d'être récompensé : victoire 25, 50 ou 90 pièces selon le niveau de l'IA, +50 % sur un KO ou une soumission, 5 pièces pour une défaite, dans la limite de 600 pièces par jour. Hors ligne, la récompense est envoyée au retour du réseau.
- Défis « Gagner des combats » activés et 6 nouveaux succès de combat. Tes derniers combats sont listés dans l'onglet Combat.


## 0.3.6

Combattants
- 84 nouveaux combattants : tous les classés UFC qui manquaient (top 15 de chaque catégorie, hommes et femmes), les Français sous contrat (Benoît Saint-Denis, Salahdine Parnasse, Nora Cornolle, Farès Ziam, Morgan Charrière, Oumar Sy…), Michael « Venom » Page, Reinier de Ridder et Francis Ngannou.
- Saison 2026 passe à 213 cartes (numéros 130 à 213 pour les nouveaux ; les cartes existantes gardent leur numéro).
- 11 anciens champions UFC sont désormais reconnus comme tels (Khabib, Oliveira, Błachowicz…) : ils ont accès à la Légendaire Ceinture d'Or.

Photos des cartes
- Photos officielles selon la rareté : en combat de la Commune à l'Épique, célébration après une victoire pour la Légendaire, ceinture ou célébration de titre pour les champions.
- 450 photos vérifiées (légende d'agence, reconnaissance faciale, revue visuelle), recadrées au format carte, 52 Ko en moyenne.


Économie (fin de la phase 3)
- Menu : l'icône Profil de la barre du bas devient un menu qui glisse de la droite, avec Compte, Boutique et ton solde de pièces et de fragments.
- Boutique : boosters à acheter en pièces et Atelier. Les pièces affichées sur l'accueil ouvrent aussi la Boutique.
- Atelier : recycle tes doublons en fragments (tout d'un coup ou un par un depuis la fiche) et fabrique une carte précise avec des fragments. Barème exigeant : Commune 5, Peu commune 15, Rare 40, Épique 100, Légendaire 400 au recyclage ; la fabrication coûte 6 fois plus. Les cartes numérotées ne se recyclent ni ne se fabriquent, et tu peux protéger une carte.
- Défis : 4 défis du jour et 3 de la semaine (ouvrir des boosters, révéler des raretés, obtenir des cartes nouvelles, recycler, fabriquer, modifier ta vitrine…), renouvelés à minuit et le lundi, avec une pastille sur l'accueil.
- Succès : 17 objectifs permanents (boosters ouverts, cartes différentes, première Légendaire et Mythique, séries complètes, vitrine pleine…), dans le Compte.
- Toutes les pièces et fragments gagnés ou dépensés sont tracés côté serveur.


- Le logo de l'écran d'entrée (octogone noir aux anneaux multicolores, cadre en métal noir et liseré doré) est au centre du booster Standard, derrière les combattants.
- Ce logo devient aussi l'icône de l'app (Android et iOS).


Boosters
- Nouveaux sachets photo : le Standard montre 5 combattants en V (le premier devant, les autres en retrait), le Premium le combattant phare avec ses ceintures dans un cadre doré gravé, noir et or, avec un reflet doré qui suit l'inclinaison.
- Ouverture interactive : on fait passer les cartes en glissant dans n'importe quel sens ou en touchant. Chaque côté a son animation (lancée en tournoyant à gauche et à droite, envol en tournant vers le haut, chute vers le bas). Une carte encore cachée se retourne au premier geste.
- Sons premium : déchirure métallisée, envol de carte, révélations de plus en plus puissantes selon la rareté (foule et cloche pour les Légendaires ; boom, gong, chœur et foule en délire pour les Mythiques).

Ma vitrine
- Expose jusqu'à 9 cartes, dont une place d'honneur. Ajout depuis un sélecteur (les plus rares d'abord), réorganisation par appui long et glisser-déposer, retrait en mode Modifier.
- Les cartes rares sont mises en valeur (halo et socle de la couleur de leur rareté, liseré doré animé pour les Légendaires et Mythiques).
- Sauvegardée sur le serveur, accessible depuis le Profil et depuis la fiche de chaque carte (« Exposer dans ma vitrine »).
- L'aperçu des raretés s'appelle désormais « Galerie des effets ».


Écran d'entrée et navigation
- L'octogone multicolore est centré dans le grand octogone et tourne avec lui.
- Les cartes flottantes ne « sautent » plus quand l'animation repart : mouvements raccordés sans à-coup (fumée, poussière et motif du fond aussi).
- Barre de navigation en icônes seules.


Direction artistique
- Nouvel écran d'entrée à chaque lancement : l'octogone noir (motif de l'Octogone Noir) se trace puis tourne lentement, « OCTOGONE » apparaît lettre par lettre avec un reflet métallique, six cartes de prestige flottent autour (Ceinture d'Or, SuperFractor, Octogone Noir…) et s'inclinent avec le téléphone (ou la souris). Tout l'écran sert à entrer.
- Fonds animés discrets : faisceaux de projecteurs, fumée, poussière dans la lumière, motif d'octogone et grain. Ambiance forte sur l'entrée et l'accueil, légère sur les écrans de lecture.
- Fond propre à chaque rareté derrière la carte (fiche et ouverture de booster) : de plus en plus spectaculaire, jusqu'aux rayons et étincelles des Légendaires et à l'aura des Mythiques.
- Nouvelle typographie (Oswald pour les titres, Barlow pour le texte), palette chaude et cohérente, boutons, barre de navigation et fiches retravaillés, accueil animé à l'ouverture.
- Icône de l'app et écran de démarrage sombres (plus de flash blanc).
- Les animations s'arrêtent si le téléphone demande de réduire les animations.


Boosters (phase 3)
- Nouvel accueil : le booster de la collection du moment occupe l'écran (Saison 2026 en vedette), Standard et Premium côte à côte, bouton « Choisir d'autres collections » en bas à droite (2024 Topps Chrome UFC disponible aussi).
- Sachets au visuel graphique original (motif octogone), qui flottent et s'inclinent avec le téléphone.
- Ouverture : on glisse le doigt le long du haut pour déchirer, puis les cartes sont révélées une par une, les plus rares en dernier. Lueur de la couleur de la rareté, gerbe de lumière dès Rare, suspense et confettis pour les Légendaires et Mythiques, sons et vibrations. Bouton « Tout révéler » et résumé avec les cartes nouvelles.
- Boosters gratuits : illimités pendant les tests, ensuite 1 toutes les 12 h (réserve de 2). Premium et boosters supplémentaires en pièces.
- Probabilités affichées pour chaque booster (« 1 sur 25 boosters »), Légendaire garantie au moins tous les 40 boosters.
- Tirage côté serveur : numérotation unique pour tous les joueurs (un /5 n'existe qu'en 5 exemplaires), jamais deux fois la même carte dans un booster.
- Réglage pour couper les sons.


Cartes et album (phase 2)
- Cartes au style premium : photo en grand, plaque du nom, note globale, numéro dans la série (45/200), numérotation des tirages limités (12/50).
- Verso : 7 stats de jeu avec le bonus de rareté, palmarès, faits marquants, coup signature (débloqué à partir d'Épique).
- La carte se retourne au toucher, s'incline avec le téléphone (reflets holographiques qui bougent) et se zoome à deux doigts.
- 12 raretés originales avec leur effet : Acier d'Octogone, Néon Main Event, Face-à-Face, Cicatrice, Onde de Choc, Clé Fatale, Main Levée, Ceinture d'Or, Héritage, Moment Historique, Trilogie, Octogone Noir. Parallèles réels : Refractor, X-Fractor, Prism, Speckle, Sepia, Negative, couleurs numérotées, SuperFractor 1/1.
- Album en classeur : pages de 9 cartes, emplacements vides numérotés, complétion par série, filtres (rareté, catégorie, possédées, nom), vue checklist.
- Vitrine des effets pour voir chaque rareté.
- Pack de bienvenue : 15 cartes offertes une fois, dont des rares.
- Toute l'app suit la langue du téléphone (français ou anglais).

Données
- 78 rivalités réelles (dont 15 trilogies) et UFC Freedom 250 pour les cartes spéciales.
- Coup signature : la technique de finition la plus marquante de chaque combattant.

## 0.1.1

Fiche combattant
- Distinctions courtes (6 lignes au plus) : titres, défenses de titre, Hall of Fame, combattant de l'année, records UFC, bonus.
- Distinctions affichées dans la langue du téléphone (français ou anglais, repli sur le français).
- Retrait de la mention « Wikipedia, en anglais » et de la section Sources.

Données
- 17 combattants qui portaient les données d'un autre (mauvais article Wikipedia) sont corrigés.
- 169 photos libres, toutes vérifiées ; Saison 2026 recalculée (129 cartes).

## 0.1.0

Première version (phase 1, fondations)
- Comptes (email, mot de passe, pseudo), code ami.
- 252 combattants réels avec stats officielles, stats de jeu 0-99.
- Édition 2024 Topps Chrome UFC complète (769 cartes, 152 parallèles) et Saison 2026.
- Contenu disponible hors ligne, synchronisé depuis Supabase.
