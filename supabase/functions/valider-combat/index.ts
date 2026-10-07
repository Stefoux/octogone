// Vérification d'un combat contre l'IA.
//
// L'app envoie le journal du combat (ses choix, ses mini-jeux, ses cartes
// Tactique) ; la fonction le rejoue avec les règles de game_core compilées en
// JavaScript (game_core.js, scripts/build_game_core_js.sh) à partir de ce que
// le serveur a lui-même noté au début du combat (graine, carte, adversaire,
// réglages). Si le journal correspond au combat recalculé, _terminer_combat
// enregistre le résultat et crédite la récompense ; sinon le combat est refusé.
import { createClient } from "jsr:@supabase/supabase-js@2";
import "./game_core.js";

type Json = Record<string, unknown>;

// deno-lint-ignore no-explicit-any
const replay = (globalThis as any).octogoneReplay as (input: string) => string;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: Json, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

/** Clé de service : ancienne variable, ou première clé secrète (nouvelles clés d'API). */
function serviceKey(): string {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}") as Record<string, string>;
  return Object.values(keys)[0];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey(), { auth: { persistSession: false } });
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: auth, error: authError } = await admin.auth.getUser(jwt);
    const user = auth?.user;
    if (authError || !user) return json({ erreur: "connexion requise" }, 401);

    const body = (await req.json()) as Json;
    const journal = Array.isArray(body.journal) ? body.journal : null;
    const habitudes = (body.habitudes ?? null) as Json | null;
    const tactiques = (Array.isArray(body.tactiques) ? body.tactiques : []) as Json[];
    if (typeof body.combat_id !== "string" || journal == null) return json({ erreur: "requête invalide" }, 400);

    const { data: cb } = await admin.from("combats").select("*")
      .eq("id", body.combat_id).eq("user_id", user.id).maybeSingle();
    if (!cb) return json({ erreur: "combat introuvable" }, 404);
    if (cb.statut !== "en_cours") return json({ statut: cb.statut, pieces: cb.pieces, deja: true });

    // Les deux combattants, tels que l'app les a vus (retouche admin prioritaire)
    const { data: fighters } = await admin.from("fighters")
      .select("id, nom, categorie, sexe, stats_jeu, stats_jeu_override, ufc")
      .in("id", [cb.combattant, cb.adversaire]);
    const fighter = (id: string, rarete: string, bonus: number | null) => {
      const f = fighters?.find((x) => x.id === id);
      if (!f) return null;
      const override = f.stats_jeu_override as Json | null;
      return {
        id: f.id,
        nom: f.nom,
        categorie: f.categorie,
        sexe: f.sexe,
        stats_jeu: override && Object.keys(override).length > 0 ? override : f.stats_jeu,
        rarete,
        bonus_stats: bonus,
        technique: (f.ufc as Json | null)?.technique_favorite
          ? ((f.ufc as Json).technique_favorite as Json).technique ?? null
          : null,
      };
    };
    const joueur = fighter(cb.combattant, cb.rarete, cb.bonus_stats);
    const adversaire = fighter(cb.adversaire, cb.adversaire_rarete, null);

    // Cartes Tactique déclarées : 2 au plus, possédées, effet et rareté conformes
    let tactiquesOk = tactiques.length <= 2;
    if (tactiquesOk && tactiques.length > 0) {
      const { data: owned } = await admin.from("owned_cards")
        .select("id, owner_id, cards(tactique), variants(rarete)")
        .in("id", tactiques.map((t) => String(t.owned_id)));
      tactiquesOk = tactiques.every((t) =>
        owned?.some((o) => {
          // deno-lint-ignore no-explicit-any
          const r = o as any;
          return r.id === t.owned_id && r.owner_id === user.id && r.cards?.tactique === t.type &&
            r.variants?.rarete === t.rarete;
        })
      );
    }

    let resultat: Json | null = null;
    if (tactiquesOk && joueur && adversaire) {
      const out = JSON.parse(replay(JSON.stringify({
        config: { seed: cb.graine, format: cb.format, titre: cb.titre, poids_libre: cb.poids_libre },
        joueur,
        adversaire,
        niveau: cb.niveau,
        habitudes,
        tactiques,
        journal,
      }))) as Json;
      if (out.ok === true) resultat = out.resultat as Json;
    }

    const { data, error } = await admin.rpc("_terminer_combat", {
      p_id: cb.id,
      p_valide: resultat != null,
      p_vainqueur: resultat?.vainqueur ?? null,
      p_methode: resultat?.methode ?? null,
      p_round: resultat?.round ?? null,
      p_journal: journal,
      p_habitudes: habitudes,
      p_tactiques: tactiques,
    });
    if (error) throw error;
    return json({ ...(data as Json), resultat });
  } catch (e) {
    return json({ erreur: e instanceof Error ? e.message : String(e) }, 500);
  }
});
