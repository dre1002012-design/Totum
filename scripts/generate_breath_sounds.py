#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère les sons pré-rendus du module Respiration (Priorité 46, retour
d'Alex après 2 tours d'échec de la synthèse temps réel dans le navigateur :
"le son est nul... c'est stressant... marche pas bien"). Recherché ce que
font les vraies apps de référence (RespiRelax notamment, citée par Alex) :
PAS de synthèse continue à balayage de fréquence — un simple carillon aux
transitions inspire/expire/rétention, posé sur une nappe de fond fixe qui
boucle indépendamment du timing des phases. Beaucoup plus simple, beaucoup
plus fiable (fichiers statiques, lecture standard — même mécanisme que
l'ancien assets/sounds/*.mp3, en mieux conçu cette fois), et permet un usage
les yeux fermés sans dépendre d'un rendu temps réel fragile.

3 carillons courts (timbre distinct pour qu'on sache, les yeux fermés, s'il
faut inspirer/expirer/retenir) + 1 nappe de fond continue en boucle
parfaite (texture de bruit rose filtré — le "petit souffle" qu'Alex a
explicitement validé comme correct dans le retour précédent).

Usage : python3 scripts/generate_breath_sounds.py
Sortie : assets/sounds/breath_{inhale,exhale,hold}_chime.wav,
         assets/sounds/breath_ambient_loop.wav
"""
import math
import random
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = 'assets/sounds'


def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    """samples : liste de float dans [-1, 1]."""
    with wave.open(path, 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)  # 16 bits
        f.setframerate(sample_rate)
        frames = b''.join(
            struct.pack('<h', max(-32768, min(32767, int(s * 32000))))
            for s in samples
        )
        f.writeframes(frames)


def equal_power(x):
    """x dans [0,1] -> courbe de fondu equal-power (plus naturelle qu'un fondu linéaire)."""
    return math.sin(max(0.0, min(1.0, x)) * math.pi / 2)


def bell_tone(duration_s, freq_start, freq_end, decay_rate=3.0, harmonics=(1.0, 0.5, 0.25)):
    """Carillon façon bol chantant : balayage de fréquence doux + quelques
    harmoniques + enveloppe en décroissance exponentielle (attaque quasi
    instantanée, longue traîne qui s'éteint doucement — le son typique d'un
    "ding" de méditation, pas un bip électronique)."""
    n = int(duration_s * SAMPLE_RATE)
    out = [0.0] * n
    phase = [0.0] * len(harmonics)
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / max(1, n - 1)
        freq = freq_start + (freq_end - freq_start) * progress
        envelope = math.exp(-decay_rate * t)
        # Attaque douce sur les 15 premières ms pour éviter tout clic.
        attack = min(1.0, t / 0.015)
        sample = 0.0
        for h_idx, h_level in enumerate(harmonics):
            harmonic_mult = h_idx + 1
            phase[h_idx] += 2 * math.pi * freq * harmonic_mult / SAMPLE_RATE
            sample += h_level * math.sin(phase[h_idx])
        out[i] = sample * envelope * attack
    # Normalisation à une amplitude crête sûre (~-6dBFS avant le mixage final).
    peak = max(abs(s) for s in out) or 1.0
    return [s / peak * 0.5 for s in out]


def generate_chimes():
    # Inspire : carillon montant (330→440Hz) — évoque une ouverture/élévation.
    write_wav(f'{OUT_DIR}/breath_inhale_chime.wav',
              bell_tone(1.6, 330, 440, decay_rate=2.2))
    # Expire : carillon descendant (440→330Hz) — évoque un relâchement.
    write_wav(f'{OUT_DIR}/breath_exhale_chime.wav',
              bell_tone(1.6, 440, 330, decay_rate=2.2))
    # Rétention : un seul "ding" fixe (392Hz, sol), pas de balayage — timbre
    # nettement différent des 2 précédents pour qu'on distingue "je tiens"
    # de "je change de sens", même les yeux fermés.
    write_wav(f'{OUT_DIR}/breath_hold_chime.wav',
              bell_tone(1.3, 392, 392, decay_rate=3.2, harmonics=(1.0, 0.35, 0.5)))
    print('OK -> 3 carillons générés.')


def generate_ambient_loop(duration_s=30.0):
    """Nappe de fond continue en boucle — bruit rose filtré (validé par Alex
    : "le petit souffle derrière pourrait faire l'affaire"), SANS la
    sinusoïde qui posait problème. Bouclage parfait : le bruit rose est une
    texture statistique sans hauteur ni rythme fixe, un point de bouclage
    n'y est donc jamais perceptible comme une "couture" (contrairement à un
    contenu mélodique) — pas besoin de fondu enchaîné complexe, juste une
    légère fondu d'1s à chaque extrémité pour éviter un micro-clic au
    raccord exact du fichier.
    """
    n = int(duration_s * SAMPLE_RATE)
    out = [0.0] * n
    # Filtre "economy" de Paul Kellet (même formule que le moteur temps réel
    # précédent) + un filtre passe-bas simple à réponse impulsionnelle finie
    # (moyenne glissante légère) pour adoucir encore le grain, façon "vent
    # lointain" plutôt que "radio mal réglée".
    b0 = b1 = b2 = 0.0
    lp_prev = 0.0
    fade_samples = int(1.0 * SAMPLE_RATE)
    for i in range(n):
        white = random.uniform(-1, 1)
        b0 = 0.99765 * b0 + white * 0.0990460
        b1 = 0.96300 * b1 + white * 0.2965164
        b2 = 0.57000 * b2 + white * 1.0526913
        pink = (b0 + b1 + b2 + white * 0.1848) * 0.11
        # Passe-bas 1 pôle doux (coupure ~800Hz) pour un grain "souffle",
        # pas "friture" — coefficient choisi empiriquement pour ce rendu.
        lp_prev = lp_prev + 0.08 * (pink - lp_prev)
        sample = lp_prev
        if i < fade_samples:
            sample *= equal_power(i / fade_samples)
        elif i > n - fade_samples:
            sample *= equal_power((n - i) / fade_samples)
        out[i] = sample
    peak = max(abs(s) for s in out) or 1.0
    out = [s / peak * 0.55 for s in out]  # -5 dBFS crête, nappe discrète
    write_wav(f'{OUT_DIR}/breath_ambient_loop.wav', out)
    print(f'OK -> nappe de fond générée ({duration_s:.0f}s, bouclage parfait).')


def generate_metronome_tick():
    """Tic de métronome doux pendant les rétentions (Priorité 53, 14/08/2026,
    retour d'Alex : "un métronome pendant les rétentions... ultra cohérent
    et pertinent, et assez doux"), en plus de la nappe de fond qui continue.
    Bref "toc" feutré (~90ms) : bruit passe-bas très serré (grain sourd, pas
    un clic électronique net) + décroissance rapide — pensé pour rester un
    simple repère de rythme discret, jamais dominant sur la nappe de fond
    ni de nature à surprendre en pleine rétention."""
    duration_s = 0.09
    n = int(duration_s * SAMPLE_RATE)
    out = [0.0] * n
    lp_prev = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        white = random.uniform(-1, 1)
        lp_prev = lp_prev + 0.15 * (white - lp_prev)  # passe-bas serré, grain sourd
        envelope = math.exp(-45 * t)  # décroissance rapide (~20ms utiles)
        out[i] = lp_prev * envelope
    peak = max(abs(s) for s in out) or 1.0
    out = [s / peak * 0.35 for s in out]  # discret, toujours sous la nappe/les carillons
    write_wav(f'{OUT_DIR}/breath_metronome_tick.wav', out)
    print('OK -> tic de métronome généré.')


if __name__ == '__main__':
    generate_chimes()
    generate_ambient_loop()
    generate_metronome_tick()
