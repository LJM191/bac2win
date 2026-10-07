Bac2Win — projet migré vers Supabase

Le site utilise maintenant :
- Supabase Auth pour les comptes.
- Supabase Database pour la progression, les profils et le classement.
- Netlify uniquement pour héberger le HTML.

Fichiers importants :
- index.html : site complet modifié pour Supabase.
- supabase-schema.sql : schéma SQL complet.
- supabase-legacy-import.sql : import des anciennes données Netlify par email.
Variables Supabase :
- La clé publique Supabase est dans index.html.
- Ne mets jamais la service_role key dans index.html.
