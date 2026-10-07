BAC2WIN — MIGRATION SUPABASE

Ce projet a été modifié pour utiliser Supabase à la place de Netlify Identity / Netlify Blobs.

Déjà fait dans le HTML :
- Connexion email/mot de passe avec Supabase Auth.
- Inscription avec Supabase Auth.
- Boutons Google et GitHub branchés sur Supabase OAuth.
- Message de confirmation changé en Supabase.
- Sauvegarde des données utilisateur dans public.user_data.
- Profil dans public.profiles.
- Classement dans public.leaderboard.
- Migration douce : si une ancienne donnée Netlify existe avec le même email dans public.legacy_netlify_data, elle est récupérée au premier login Supabase.

Déjà fait sur le projet Supabase Bac2win :
- Tables profiles, user_data, leaderboard, legacy_netlify_data créées.
- RLS activé.
- Policies de sécurité ajoutées.
- Trigger updated_at ajouté.

À faire dans Supabase Dashboard :
1. Authentication > Providers
   - Activer Google si tu veux le bouton Google.
   - Activer GitHub si tu veux le bouton GitHub.
   - Ajouter les Client ID / Client Secret donnés par Google/GitHub.

2. Authentication > URL Configuration
   - Site URL : URL de ton site Netlify.
   - Redirect URLs : URL de ton site Netlify.

3. Anciennes données Netlify
   - Le fichier supabase-legacy-import.sql contient les anciennes progressions exportées.
   - Tu peux l’exécuter dans Supabase SQL Editor.
   - Ensuite, les élèves doivent recréer/se connecter avec le même email : leur progression est restaurée automatiquement.

Important :
- Les anciens mots de passe Netlify Identity ne sont pas récupérables.
- Pour éviter de perdre les comptes, dis aux élèves d’utiliser le même email et “mot de passe oublié”/nouvelle inscription Supabase.
- Netlify reste seulement l’hébergement du site.

Commandes de publication :
netlify link
netlify deploy --prod --dir .
