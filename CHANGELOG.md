# Versions d'Octogone

Chaque version publiée a sa release GitHub avec les APK Android (`scripts/release_android.sh`).
Le texte d'une section sert de notes à la release correspondante.

## 0.3.1

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
