"""
Migration 006: Temple Redesign

Adds tables and seed data for the redesigned Temple experience:
- user_temple_activity: Track bell rings, daily visits, etc.
- vedic_entries: Library of Vedic shlokas, teachings, and wisdom
- ALTER pooja_types: add steps, deity_description, significance columns
- Seed ~50 vedic entries across 6 categories
- Seed DIY pooja steps + 2 new pooja types

Created: 2026-02-08
"""

from __future__ import annotations

import json
import sqlite3
import uuid
from datetime import datetime

VERSION = 6
NAME = "temple_redesign"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()

    # =========================================================================
    # user_temple_activity
    # =========================================================================
    cur.execute("""
        CREATE TABLE IF NOT EXISTS user_temple_activity (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            activity_type TEXT NOT NULL,
            data TEXT,
            created_at TEXT NOT NULL
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_temple_activity_user
        ON user_temple_activity(user_id, activity_type)
    """)

    # =========================================================================
    # vedic_entries
    # =========================================================================
    cur.execute("""
        CREATE TABLE IF NOT EXISTS vedic_entries (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            sanskrit_text TEXT,
            transliteration TEXT,
            translation TEXT NOT NULL,
            source TEXT,
            tags TEXT,
            sort_order INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_vedic_entries_category
        ON vedic_entries(category, is_active)
    """)

    # =========================================================================
    # ALTER pooja_types: add steps, deity_description, significance
    # =========================================================================
    cur.execute("PRAGMA table_info(pooja_types)")
    existing_cols = {row[1] for row in cur.fetchall()}

    if "steps" not in existing_cols:
        cur.execute("ALTER TABLE pooja_types ADD COLUMN steps TEXT")
    if "deity_description" not in existing_cols:
        cur.execute("ALTER TABLE pooja_types ADD COLUMN deity_description TEXT")
    if "significance" not in existing_cols:
        cur.execute("ALTER TABLE pooja_types ADD COLUMN significance TEXT")

    # =========================================================================
    # Seed vedic entries
    # =========================================================================
    _seed_vedic_entries(cur)

    # =========================================================================
    # Seed pooja steps + new pooja types
    # =========================================================================
    _seed_pooja_steps(cur)

    conn.commit()


# ---------------------------------------------------------------------------
# Vedic entries seed data (~50 entries across 6 categories)
# ---------------------------------------------------------------------------

def _seed_vedic_entries(cur: sqlite3.Cursor) -> None:
    cur.execute("SELECT COUNT(*) FROM vedic_entries")
    if cur.fetchone()[0] > 0:
        return

    now = datetime.utcnow().isoformat()

    entries = [
        # ===== Dharma (10) =====
        {
            "category": "Dharma",
            "title": "Dharma Sustains All",
            "sanskrit_text": "\u0927\u0930\u094d\u092e\u094b \u0930\u0915\u094d\u0937\u0924\u093f \u0930\u0915\u094d\u0937\u093f\u0924\u0903",
            "transliteration": "Dharmo rakshati rakshitah",
            "translation": "Dharma protects those who protect dharma.",
            "source": "Manusmriti 8.15",
            "tags": json.dumps(["dharma", "protection", "righteousness"]),
        },
        {
            "category": "Dharma",
            "title": "Truth Alone Triumphs",
            "sanskrit_text": "\u0938\u0924\u094d\u092f\u092e\u0947\u0935 \u091c\u092f\u0924\u0947 \u0928\u093e\u0928\u0943\u0924\u092e\u094d",
            "transliteration": "Satyameva jayate naanritam",
            "translation": "Truth alone triumphs, not falsehood.",
            "source": "Mundaka Upanishad 3.1.6",
            "tags": json.dumps(["truth", "victory", "upanishad"]),
        },
        {
            "category": "Dharma",
            "title": "Non-violence is Supreme Dharma",
            "sanskrit_text": "\u0905\u0939\u093f\u0902\u0938\u093e \u092a\u0930\u092e\u094b \u0927\u0930\u094d\u092e\u0903",
            "transliteration": "Ahimsa paramo dharmah",
            "translation": "Non-violence is the highest moral virtue.",
            "source": "Mahabharata, Anushasana Parva 116.38",
            "tags": json.dumps(["ahimsa", "non-violence", "virtue"]),
        },
        {
            "category": "Dharma",
            "title": "The Self is the Friend",
            "sanskrit_text": "\u0909\u0926\u094d\u0927\u0930\u0947\u0926\u093e\u0924\u094d\u092e\u0928\u093e\u0924\u094d\u092e\u093e\u0928\u0902 \u0928\u093e\u0924\u094d\u092e\u093e\u0928\u092e\u0935\u0938\u093e\u0926\u092f\u0947\u0924\u094d",
            "transliteration": "Uddhared atmanatmanam natmanam avasadayet",
            "translation": "One must elevate oneself by one's own mind, not degrade oneself.",
            "source": "Bhagavad Gita 6.5",
            "tags": json.dumps(["self", "elevation", "gita"]),
        },
        {
            "category": "Dharma",
            "title": "Vasudhaiva Kutumbakam",
            "sanskrit_text": "\u0935\u0938\u0941\u0927\u0948\u0935 \u0915\u0941\u091f\u0941\u092e\u094d\u092c\u0915\u092e\u094d",
            "transliteration": "Vasudhaiva kutumbakam",
            "translation": "The whole world is one family.",
            "source": "Maha Upanishad 6.71-75",
            "tags": json.dumps(["unity", "family", "world"]),
        },
        {
            "category": "Dharma",
            "title": "Duty Without Attachment",
            "sanskrit_text": "\u0915\u0930\u094d\u092e\u0923\u094d\u092f\u0947\u0935\u093e\u0927\u093f\u0915\u093e\u0930\u0938\u094d\u0924\u0947 \u092e\u093e \u092b\u0932\u0947\u0937\u0941 \u0915\u0926\u093e\u091a\u0928",
            "transliteration": "Karmanyevadhikaraste ma phaleshu kadachana",
            "translation": "You have the right to perform your duty, but never to its fruits.",
            "source": "Bhagavad Gita 2.47",
            "tags": json.dumps(["karma", "duty", "detachment", "gita"]),
        },
        {
            "category": "Dharma",
            "title": "Knowledge is the Greatest Purifier",
            "sanskrit_text": "\u0928 \u0939\u093f \u091c\u094d\u091e\u093e\u0928\u0947\u0928 \u0938\u0926\u0943\u0936\u0902 \u092a\u0935\u093f\u0924\u094d\u0930\u092e\u093f\u0939 \u0935\u093f\u0926\u094d\u092f\u0924\u0947",
            "transliteration": "Na hi jnanena sadrisham pavitram iha vidyate",
            "translation": "There is nothing as purifying as knowledge in this world.",
            "source": "Bhagavad Gita 4.38",
            "tags": json.dumps(["knowledge", "purity", "gita"]),
        },
        {
            "category": "Dharma",
            "title": "Equanimity of Mind",
            "sanskrit_text": "\u0938\u092e\u0924\u094d\u0935\u0902 \u092f\u094b\u0917 \u0909\u091a\u094d\u092f\u0924\u0947",
            "transliteration": "Samatvam yoga uchyate",
            "translation": "Equanimity of mind is called Yoga.",
            "source": "Bhagavad Gita 2.48",
            "tags": json.dumps(["yoga", "equanimity", "balance", "gita"]),
        },
        {
            "category": "Dharma",
            "title": "Lead Me from Darkness to Light",
            "sanskrit_text": "\u0924\u092e\u0938\u094b \u092e\u093e \u091c\u094d\u092f\u094b\u0924\u093f\u0930\u094d\u0917\u092e\u092f",
            "transliteration": "Tamaso ma jyotirgamaya",
            "translation": "Lead me from darkness to light.",
            "source": "Brihadaranyaka Upanishad 1.3.28",
            "tags": json.dumps(["light", "darkness", "prayer", "upanishad"]),
        },
        {
            "category": "Dharma",
            "title": "The Wise See All Equally",
            "sanskrit_text": "\u0935\u093f\u0926\u094d\u092f\u093e\u0935\u093f\u0928\u092f\u0938\u092e\u094d\u092a\u0928\u094d\u0928\u0947 \u092c\u094d\u0930\u093e\u0939\u094d\u092e\u0923\u0947 \u0917\u0935\u093f \u0939\u0938\u094d\u0924\u093f\u0928\u093f",
            "transliteration": "Vidya-vinaya-sampanne brahmane gavi hastini",
            "translation": "The wise see with equal vision a learned Brahmin, a cow, an elephant, a dog, and an outcaste.",
            "source": "Bhagavad Gita 5.18",
            "tags": json.dumps(["equality", "wisdom", "vision", "gita"]),
        },

        # ===== Karma (8) =====
        {
            "category": "Karma",
            "title": "As You Sow, So Shall You Reap",
            "sanskrit_text": "\u092f\u0926\u094d\u092d\u093e\u0935\u0902 \u0924\u0926\u094d\u092d\u0935\u0924\u093f",
            "transliteration": "Yadbhavam tadbhavati",
            "translation": "As is one's thought, so one becomes.",
            "source": "Upanishadic teaching",
            "tags": json.dumps(["karma", "thought", "intention"]),
        },
        {
            "category": "Karma",
            "title": "Action is Superior to Inaction",
            "sanskrit_text": "\u0928\u093f\u092f\u0924\u0902 \u0915\u0941\u0930\u0941 \u0915\u0930\u094d\u092e \u0924\u094d\u0935\u0902 \u0915\u0930\u094d\u092e \u091c\u094d\u092f\u093e\u092f\u094b \u0939\u094d\u092f\u0915\u0930\u094d\u092e\u0923\u0903",
            "transliteration": "Niyatam kuru karma tvam karma jyayo hyakarmanah",
            "translation": "Perform your prescribed duty, for action is superior to inaction.",
            "source": "Bhagavad Gita 3.8",
            "tags": json.dumps(["action", "duty", "karma", "gita"]),
        },
        {
            "category": "Karma",
            "title": "The Three Gunas and Action",
            "sanskrit_text": "\u092a\u094d\u0930\u0915\u0943\u0924\u0947\u0903 \u0915\u094d\u0930\u093f\u092f\u092e\u093e\u0923\u093e\u0928\u093f \u0917\u0941\u0923\u0948\u0903 \u0915\u0930\u094d\u092e\u093e\u0923\u093f \u0938\u0930\u094d\u0935\u0936\u0903",
            "transliteration": "Prakriteh kriyamanani gunaih karmani sarvashah",
            "translation": "All actions are performed by the gunas (qualities) of nature. The self deluded by ego thinks 'I am the doer.'",
            "source": "Bhagavad Gita 3.27",
            "tags": json.dumps(["gunas", "nature", "ego", "gita"]),
        },
        {
            "category": "Karma",
            "title": "Selfless Service",
            "sanskrit_text": "\u0928\u093f\u0937\u094d\u0915\u093e\u092e \u0915\u0930\u094d\u092e",
            "transliteration": "Nishkama karma",
            "translation": "Selfless action performed without desire for results leads to liberation.",
            "source": "Bhagavad Gita",
            "tags": json.dumps(["selfless", "service", "liberation"]),
        },
        {
            "category": "Karma",
            "title": "Yoga of Action",
            "sanskrit_text": "\u092f\u094b\u0917\u0903 \u0915\u0930\u094d\u092e\u0938\u0941 \u0915\u094c\u0936\u0932\u092e\u094d",
            "transliteration": "Yogah karmasu kaushalam",
            "translation": "Yoga is skill in action.",
            "source": "Bhagavad Gita 2.50",
            "tags": json.dumps(["yoga", "skill", "action", "gita"]),
        },
        {
            "category": "Karma",
            "title": "Past Actions Shape Present",
            "sanskrit_text": "\u0905\u0935\u0936\u094d\u092f\u092e\u0947\u0935 \u092d\u094b\u0915\u094d\u0924\u0935\u094d\u092f\u0902 \u092a\u0942\u0930\u094d\u0935\u0915\u0930\u094d\u092e\u092b\u0932\u092e\u094d",
            "transliteration": "Avashyameva bhoktavyam purva karma phalam",
            "translation": "One must inevitably experience the fruits of past actions.",
            "source": "Brahma Vaivarta Purana",
            "tags": json.dumps(["karma", "fruit", "consequence"]),
        },
        {
            "category": "Karma",
            "title": "Right Action in Crisis",
            "sanskrit_text": "\u0906\u092a\u0926\u093f \u0927\u0930\u094d\u092e\u0947\u0923 \u0928\u093e\u0928\u0943\u0924\u092e\u094d",
            "transliteration": "Apadi dharmena naanritam",
            "translation": "In times of crisis, follow dharma, not falsehood.",
            "source": "Mahabharata",
            "tags": json.dumps(["crisis", "dharma", "truth"]),
        },
        {
            "category": "Karma",
            "title": "Detached Offering",
            "sanskrit_text": "\u092f\u0924\u094d\u0915\u0930\u094b\u0937\u093f \u092f\u0926\u0936\u094d\u0928\u093e\u0938\u093f \u092f\u091c\u094d\u091c\u0941\u0939\u094b\u0937\u093f \u0926\u0926\u093e\u0938\u093f \u092f\u0924\u094d",
            "transliteration": "Yat karoshi yad ashnasi yaj juhoshi dadasi yat",
            "translation": "Whatever you do, eat, offer in sacrifice, or give away -- do it as an offering to Me.",
            "source": "Bhagavad Gita 9.27",
            "tags": json.dumps(["offering", "devotion", "surrender", "gita"]),
        },

        # ===== Rituals (8) =====
        {
            "category": "Rituals",
            "title": "The Sacred Fire",
            "sanskrit_text": "\u0905\u0917\u094d\u0928\u093f\u092e\u0940\u0933\u0947 \u092a\u0941\u0930\u094b\u0939\u093f\u0924\u092e\u094d",
            "transliteration": "Agnimile purohitam",
            "translation": "I worship Agni, the household priest, the divine minister of sacrifice.",
            "source": "Rig Veda 1.1.1",
            "tags": json.dumps(["agni", "fire", "sacrifice", "rigveda"]),
        },
        {
            "category": "Rituals",
            "title": "Gayatri Mantra",
            "sanskrit_text": "\u0913\u0902 \u092d\u0942\u0930\u094d\u092d\u0941\u0935\u0903 \u0938\u094d\u0935\u0903 \u0924\u0924\u094d\u0938\u0935\u093f\u0924\u0941\u0930\u094d\u0935\u0930\u0947\u0923\u094d\u092f\u0902 \u092d\u0930\u094d\u0917\u094b \u0926\u0947\u0935\u0938\u094d\u092f \u0927\u0940\u092e\u0939\u093f \u0927\u093f\u092f\u094b \u092f\u094b \u0928\u0903 \u092a\u094d\u0930\u091a\u094b\u0926\u092f\u093e\u0924\u094d",
            "transliteration": "Om bhur bhuvah svah tat savitur varenyam bhargo devasya dhimahi dhiyo yo nah prachodayat",
            "translation": "We meditate on the glory of the Creator who has created the Universe, who is worthy of worship, who is the embodiment of knowledge and light. May He enlighten our intellect.",
            "source": "Rig Veda 3.62.10",
            "tags": json.dumps(["gayatri", "mantra", "sun", "meditation"]),
        },
        {
            "category": "Rituals",
            "title": "Shanti Mantra",
            "sanskrit_text": "\u0913\u092e\u094d \u0938\u0939 \u0928\u093e\u0935\u0935\u0924\u0941 \u0938\u0939 \u0928\u094c \u092d\u0941\u0928\u0915\u094d\u0924\u0941 \u0938\u0939 \u0935\u0940\u0930\u094d\u092f\u0902 \u0915\u0930\u0935\u093e\u0935\u0939\u0948",
            "transliteration": "Om saha navavatu saha nau bhunaktu saha viryam karavavahai",
            "translation": "May we be protected together, may we be nourished together, may we work together with great energy.",
            "source": "Taittiriya Upanishad",
            "tags": json.dumps(["shanti", "peace", "prayer", "upanishad"]),
        },
        {
            "category": "Rituals",
            "title": "Aarti Prayer",
            "sanskrit_text": "\u0913\u0902 \u091c\u092f \u091c\u0917\u0926\u0940\u0936 \u0939\u0930\u0947",
            "transliteration": "Om jai jagadish hare",
            "translation": "Victory to the Lord of the Universe. O Lord, remover of devotees' suffering.",
            "source": "Traditional Aarti",
            "tags": json.dumps(["aarti", "worship", "prayer"]),
        },
        {
            "category": "Rituals",
            "title": "Offering of Light",
            "sanskrit_text": "\u0926\u0940\u092a\u091c\u094d\u092f\u094b\u0924\u093f\u0903 \u092a\u0930\u093e\u0924\u094d\u092a\u0930 \u092c\u094d\u0930\u0939\u094d\u092e",
            "transliteration": "Deepajyotih paratpara brahma",
            "translation": "The light of the lamp represents the supreme Brahman, the ultimate reality.",
            "source": "Traditional Deepa Mantra",
            "tags": json.dumps(["lamp", "light", "brahman"]),
        },
        {
            "category": "Rituals",
            "title": "Sankalpa - Sacred Resolve",
            "sanskrit_text": "\u092e\u092e \u0909\u092a\u093e\u0924\u094d\u0924 \u0938\u092e\u0938\u094d\u0924 \u0926\u0941\u0930\u093f\u0924\u0915\u094d\u0937\u092f\u0926\u094d\u0935\u093e\u0930\u093e",
            "transliteration": "Mama upatta samasta duritakshaya dvara",
            "translation": "For the removal of all my sins and obstacles, I take this sacred resolve.",
            "source": "Sankalpa Mantra",
            "tags": json.dumps(["sankalpa", "resolve", "purification"]),
        },
        {
            "category": "Rituals",
            "title": "Invocation of Ganesha",
            "sanskrit_text": "\u0935\u0915\u094d\u0930\u0924\u0941\u0923\u094d\u0921 \u092e\u0939\u093e\u0915\u093e\u092f \u0938\u0942\u0930\u094d\u092f\u0915\u094b\u091f\u093f \u0938\u092e\u092a\u094d\u0930\u092d",
            "transliteration": "Vakratunda mahakaya suryakoti samaprabha",
            "translation": "O Lord with a curved trunk, large body, and brilliance of a million suns, make my endeavors free of obstacles.",
            "source": "Ganesha Shloka",
            "tags": json.dumps(["ganesha", "invocation", "obstacles"]),
        },
        {
            "category": "Rituals",
            "title": "Purna Ahuti - Complete Offering",
            "sanskrit_text": "\u0913\u0902 \u092a\u0942\u0930\u094d\u0923\u092e\u0926\u0903 \u092a\u0942\u0930\u094d\u0923\u092e\u093f\u0926\u0902 \u092a\u0942\u0930\u094d\u0923\u093e\u0924\u094d\u092a\u0942\u0930\u094d\u0923\u092e\u0941\u0926\u091a\u094d\u092f\u0924\u0947",
            "transliteration": "Om purnamadah purnamidam purnat purnamudachyate",
            "translation": "That is whole, this is whole. From the whole, the whole arises. Taking the whole from the whole, the whole remains.",
            "source": "Isha Upanishad (Invocation)",
            "tags": json.dumps(["purna", "wholeness", "upanishad"]),
        },

        # ===== Planets (9 - one per graha) =====
        {
            "category": "Planets",
            "title": "Surya (Sun) - Source of Life",
            "sanskrit_text": "\u0913\u0902 \u0938\u0942\u0930\u094d\u092f\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Suryaya Namah",
            "translation": "Salutations to the Sun, the source of all energy and life force.",
            "source": "Surya Mantra",
            "tags": json.dumps(["surya", "sun", "graha", "planet"]),
        },
        {
            "category": "Planets",
            "title": "Chandra (Moon) - Mind and Emotions",
            "sanskrit_text": "\u0913\u0902 \u091a\u0928\u094d\u0926\u094d\u0930\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Chandraya Namah",
            "translation": "Salutations to the Moon, ruler of the mind, emotions, and inner peace.",
            "source": "Chandra Mantra",
            "tags": json.dumps(["chandra", "moon", "mind", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Mangala (Mars) - Courage and Strength",
            "sanskrit_text": "\u0913\u0902 \u0905\u0919\u094d\u0917\u093e\u0930\u0915\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Angarakaya Namah",
            "translation": "Salutations to Mars, bestower of courage, strength, and victory.",
            "source": "Mangala Mantra",
            "tags": json.dumps(["mangala", "mars", "courage", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Budha (Mercury) - Intellect",
            "sanskrit_text": "\u0913\u0902 \u092c\u0941\u0927\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Budhaya Namah",
            "translation": "Salutations to Mercury, lord of intellect, communication, and wisdom.",
            "source": "Budha Mantra",
            "tags": json.dumps(["budha", "mercury", "intellect", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Guru (Jupiter) - Wisdom and Fortune",
            "sanskrit_text": "\u0913\u0902 \u092c\u0943\u0939\u0938\u094d\u092a\u0924\u092f\u0947 \u0928\u092e\u0903",
            "transliteration": "Om Brihaspataye Namah",
            "translation": "Salutations to Jupiter, the great teacher, bestower of wisdom and good fortune.",
            "source": "Guru Mantra",
            "tags": json.dumps(["guru", "jupiter", "wisdom", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Shukra (Venus) - Love and Beauty",
            "sanskrit_text": "\u0913\u0902 \u0936\u0941\u0915\u094d\u0930\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Shukraya Namah",
            "translation": "Salutations to Venus, ruler of love, beauty, art, and prosperity.",
            "source": "Shukra Mantra",
            "tags": json.dumps(["shukra", "venus", "love", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Shani (Saturn) - Discipline and Justice",
            "sanskrit_text": "\u0913\u0902 \u0936\u0928\u0948\u0936\u094d\u091a\u0930\u093e\u092f \u0928\u092e\u0903",
            "transliteration": "Om Shanaishcharaya Namah",
            "translation": "Salutations to Saturn, the lord of discipline, justice, and karmic lessons.",
            "source": "Shani Mantra",
            "tags": json.dumps(["shani", "saturn", "discipline", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Rahu - Shadow of Ambition",
            "sanskrit_text": "\u0913\u0902 \u0930\u093e\u0939\u0935\u0947 \u0928\u092e\u0903",
            "transliteration": "Om Rahave Namah",
            "translation": "Salutations to Rahu, the north node, representing worldly desires and ambition.",
            "source": "Rahu Mantra",
            "tags": json.dumps(["rahu", "node", "ambition", "graha"]),
        },
        {
            "category": "Planets",
            "title": "Ketu - Liberation and Detachment",
            "sanskrit_text": "\u0913\u0902 \u0915\u0947\u0924\u0935\u0947 \u0928\u092e\u0903",
            "transliteration": "Om Ketave Namah",
            "translation": "Salutations to Ketu, the south node, guiding spiritual liberation and detachment.",
            "source": "Ketu Mantra",
            "tags": json.dumps(["ketu", "node", "liberation", "graha"]),
        },

        # ===== Deities (9) =====
        {
            "category": "Deities",
            "title": "Ganesha - Remover of Obstacles",
            "sanskrit_text": "\u0913\u0902 \u0917\u0902 \u0917\u0923\u092a\u0924\u092f\u0947 \u0928\u092e\u0903",
            "transliteration": "Om Gam Ganapataye Namah",
            "translation": "Salutations to Lord Ganesha, the remover of all obstacles and lord of new beginnings.",
            "source": "Ganapati Mantra",
            "tags": json.dumps(["ganesha", "obstacles", "beginnings"]),
        },
        {
            "category": "Deities",
            "title": "Shiva - The Auspicious One",
            "sanskrit_text": "\u0913\u0902 \u0928\u092e\u0903 \u0936\u093f\u0935\u093e\u092f",
            "transliteration": "Om Namah Shivaya",
            "translation": "I bow to Shiva, the supreme consciousness, the auspicious one who is the inner self of all.",
            "source": "Shiva Panchakshari Mantra",
            "tags": json.dumps(["shiva", "consciousness", "auspicious"]),
        },
        {
            "category": "Deities",
            "title": "Vishnu - The Preserver",
            "sanskrit_text": "\u0913\u0902 \u0928\u092e\u094b \u0928\u093e\u0930\u093e\u092f\u0923\u093e\u092f",
            "transliteration": "Om Namo Narayanaya",
            "translation": "Salutations to Lord Vishnu, the preserver and sustainer of the universe.",
            "source": "Ashtakshari Mantra",
            "tags": json.dumps(["vishnu", "narayana", "preserver"]),
        },
        {
            "category": "Deities",
            "title": "Lakshmi - Goddess of Prosperity",
            "sanskrit_text": "\u0913\u0902 \u0936\u094d\u0930\u0940\u0902 \u092e\u0939\u093e\u0932\u0915\u094d\u0937\u094d\u092e\u094d\u092f\u0948 \u0928\u092e\u0903",
            "transliteration": "Om Shreem Mahalakshmyai Namah",
            "translation": "Salutations to Goddess Mahalakshmi, bestower of wealth, fortune, and abundance.",
            "source": "Lakshmi Mantra",
            "tags": json.dumps(["lakshmi", "prosperity", "wealth"]),
        },
        {
            "category": "Deities",
            "title": "Saraswati - Goddess of Knowledge",
            "sanskrit_text": "\u0913\u0902 \u0910\u0902 \u0938\u0930\u0938\u094d\u0935\u0924\u094d\u092f\u0948 \u0928\u092e\u0903",
            "transliteration": "Om Aim Sarasvatyai Namah",
            "translation": "Salutations to Goddess Saraswati, the divine mother of knowledge, music, and arts.",
            "source": "Saraswati Mantra",
            "tags": json.dumps(["saraswati", "knowledge", "arts"]),
        },
        {
            "category": "Deities",
            "title": "Hanuman - The Devoted Servant",
            "sanskrit_text": "\u0913\u0902 \u0939\u0928\u0941\u092e\u0924\u0947 \u0928\u092e\u0903",
            "transliteration": "Om Hanumate Namah",
            "translation": "Salutations to Lord Hanuman, the embodiment of devotion, courage, and selfless service.",
            "source": "Hanuman Mantra",
            "tags": json.dumps(["hanuman", "devotion", "courage"]),
        },
        {
            "category": "Deities",
            "title": "Durga - The Invincible",
            "sanskrit_text": "\u0913\u0902 \u0926\u0941\u0902 \u0926\u0941\u0930\u094d\u0917\u093e\u092f\u0948 \u0928\u092e\u0903",
            "transliteration": "Om Dum Durgayai Namah",
            "translation": "Salutations to Goddess Durga, the invincible divine mother who destroys evil.",
            "source": "Durga Mantra",
            "tags": json.dumps(["durga", "shakti", "protection"]),
        },
        {
            "category": "Deities",
            "title": "Krishna - The All-Attractive",
            "sanskrit_text": "\u0939\u0930\u0947 \u0915\u0943\u0937\u094d\u0923 \u0939\u0930\u0947 \u0915\u0943\u0937\u094d\u0923 \u0915\u0943\u0937\u094d\u0923 \u0915\u0943\u0937\u094d\u0923 \u0939\u0930\u0947 \u0939\u0930\u0947",
            "transliteration": "Hare Krishna Hare Krishna Krishna Krishna Hare Hare",
            "translation": "O Lord Krishna, O energy of the Lord, please engage me in Your devotional service.",
            "source": "Maha Mantra (Kali-Santarana Upanishad)",
            "tags": json.dumps(["krishna", "devotion", "maha-mantra"]),
        },
        {
            "category": "Deities",
            "title": "Rama - The Ideal King",
            "sanskrit_text": "\u0936\u094d\u0930\u0940 \u0930\u093e\u092e \u091c\u092f \u0930\u093e\u092e \u091c\u092f \u091c\u092f \u0930\u093e\u092e",
            "transliteration": "Shri Rama Jaya Rama Jaya Jaya Rama",
            "translation": "Glory to Lord Rama, the ideal embodiment of dharma, truth, and righteous conduct.",
            "source": "Rama Taraka Mantra",
            "tags": json.dumps(["rama", "dharma", "ideal"]),
        },

        # ===== Life Events (6) =====
        {
            "category": "Life Events",
            "title": "Blessing for Marriage",
            "sanskrit_text": "\u0938\u0939 \u0927\u0930\u094d\u092e\u0936\u094d\u091a\u0930\u093e\u092e\u093f",
            "transliteration": "Saha dharmashcharami",
            "translation": "Together we shall walk the path of dharma. May this union be blessed with love, respect, and spiritual growth.",
            "source": "Vivaha Mantra (Wedding Vows)",
            "tags": json.dumps(["marriage", "wedding", "vivaha"]),
        },
        {
            "category": "Life Events",
            "title": "Blessing for a Newborn",
            "sanskrit_text": "\u0906\u092f\u0941\u0937\u094d\u092e\u093e\u0928\u094d \u092d\u0930\u0924\u093e\u0917\u094d\u0928\u0947",
            "transliteration": "Ayushman bharatagney",
            "translation": "May you be blessed with long life. May you shine with the light of wisdom and bring joy to all.",
            "source": "Jatakarma Samskara",
            "tags": json.dumps(["birth", "newborn", "blessing"]),
        },
        {
            "category": "Life Events",
            "title": "Beginning of Education",
            "sanskrit_text": "\u0913\u0902 \u0928\u092e\u094b \u092d\u0917\u0935\u0924\u0947 \u0935\u093e\u0938\u0941\u0926\u0947\u0935\u093e\u092f \u0927\u0940\u092e\u0939\u093f",
            "transliteration": "Om namo bhagavate vasudevaya dhimahi",
            "translation": "We begin this sacred journey of learning. May knowledge illuminate the path and wisdom guide every step.",
            "source": "Vidyarambha Samskara",
            "tags": json.dumps(["education", "learning", "vidyarambha"]),
        },
        {
            "category": "Life Events",
            "title": "Blessing for New Home",
            "sanskrit_text": "\u0935\u093e\u0938\u094d\u0924\u094b\u0937\u094d\u092a\u0924\u093f\u0930\u094d\u092d\u0942\u092e\u093f\u092a\u0924\u093f\u0930\u094d\u092d\u0942\u092e\u093f\u092a\u0924\u0947",
            "transliteration": "Vastoshpatir bhumipatirbhumipate",
            "translation": "O Lord of the dwelling, may this home be filled with peace, prosperity, and divine protection.",
            "source": "Griha Pravesha Mantra",
            "tags": json.dumps(["home", "griha-pravesha", "blessing"]),
        },
        {
            "category": "Life Events",
            "title": "Prayer for Healing",
            "sanskrit_text": "\u0913\u0902 \u0924\u094d\u0930\u094d\u092f\u092e\u094d\u092c\u0915\u0902 \u092f\u091c\u093e\u092e\u0939\u0947 \u0938\u0941\u0917\u0928\u094d\u0927\u093f\u0902 \u092a\u0941\u0937\u094d\u091f\u093f\u0935\u0930\u094d\u0927\u0928\u092e\u094d",
            "transliteration": "Om tryambakam yajamahe sugandhim pushti-vardhanam",
            "translation": "We worship the three-eyed Lord who nourishes all. As a cucumber is freed from its stem, may He liberate us from death and grant immortality.",
            "source": "Mahamrityunjaya Mantra (Rig Veda 7.59.12)",
            "tags": json.dumps(["healing", "health", "mrityunjaya"]),
        },
        {
            "category": "Life Events",
            "title": "Prayer for Departed Souls",
            "sanskrit_text": "\u0913\u0902 \u0936\u093e\u0928\u094d\u0924\u093f\u0903 \u0936\u093e\u0928\u094d\u0924\u093f\u0903 \u0936\u093e\u0928\u094d\u0924\u093f\u0903",
            "transliteration": "Om Shantih Shantih Shantih",
            "translation": "May the departed soul find eternal peace. May the three realms -- physical, divine, and spiritual -- be at peace.",
            "source": "Shanti Mantra (Funeral Rites)",
            "tags": json.dumps(["death", "peace", "departed", "shanti"]),
        },
    ]

    for i, entry in enumerate(entries):
        cur.execute("""
            INSERT INTO vedic_entries
            (id, category, title, sanskrit_text, transliteration, translation,
             source, tags, sort_order, is_active, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
        """, (
            f"vedic_{uuid.uuid4().hex[:12]}",
            entry["category"],
            entry["title"],
            entry.get("sanskrit_text"),
            entry.get("transliteration"),
            entry["translation"],
            entry.get("source"),
            entry.get("tags"),
            i + 1,
            now,
        ))


# ---------------------------------------------------------------------------
# Pooja DIY steps seed + new pooja types
# ---------------------------------------------------------------------------

def _seed_pooja_steps(cur: sqlite3.Cursor) -> None:
    import json
    from datetime import datetime

    now = datetime.utcnow().isoformat()

    # Steps for existing pooja types
    steps_data = {
        "pooja_ganesh": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Clean the puja area. Place a clean cloth and set up the idol or image of Lord Ganesha."},
                {"step": 2, "title": "Kalash Sthapana", "description": "Fill a copper pot with water, place mango leaves, and a coconut on top. This represents the universe."},
                {"step": 3, "title": "Avahana (Invocation)", "description": "Invite Lord Ganesha by chanting 'Om Gam Ganapataye Namah' 21 times. Offer red flowers."},
                {"step": 4, "title": "Panchamrit Abhishekam", "description": "Bathe the idol with milk, curd, honey, ghee, and sugar water while chanting mantras."},
                {"step": 5, "title": "Alankara (Decoration)", "description": "Apply sindoor and haldi. Decorate with durva grass (21 blades) and red flowers."},
                {"step": 6, "title": "Naivedya (Offering)", "description": "Offer modak (5 pieces), fruits, and coconut. Light the ghee lamp and incense."},
                {"step": 7, "title": "Aarti", "description": "Perform aarti with camphor lamp, circling clockwise 3 times. Sing 'Jai Ganesh Deva'."},
                {"step": 8, "title": "Visarjan (Conclusion)", "description": "Seek blessings, offer final prayers. Distribute prasad to family and neighbors."},
            ]),
            "deity_description": "Lord Ganesha, the elephant-headed god, is the remover of obstacles and the lord of beginnings. Son of Shiva and Parvati, He is worshipped first before any auspicious ceremony.",
            "significance": "Ganesh Puja removes obstacles from one's path, brings wisdom and prosperity, and is essential before starting any new venture or journey.",
        },
        "pooja_lakshmi": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation & Cleaning", "description": "Clean the entire house, especially the puja area. Draw rangoli at the entrance with rice flour."},
                {"step": 2, "title": "Set Up Altar", "description": "Place Lakshmi idol on a red cloth. Keep a kalash filled with water, coins, and rice nearby."},
                {"step": 3, "title": "Ganesh Puja First", "description": "Begin by invoking Lord Ganesha with 'Om Gam Ganapataye Namah' as He is always worshipped first."},
                {"step": 4, "title": "Lakshmi Avahana", "description": "Invoke Goddess Lakshmi chanting 'Om Shreem Mahalakshmyai Namah' 108 times. Offer lotus flowers."},
                {"step": 5, "title": "Abhishekam", "description": "Bathe the idol with panchamrit (milk, curd, honey, ghee, sugar). Then with clean water."},
                {"step": 6, "title": "Alankara & Offerings", "description": "Drape in red cloth. Offer turmeric, kumkum, gold/silver coins, lotus flowers, and fruits."},
                {"step": 7, "title": "Light Lamps", "description": "Light ghee lamps in all corners of the house. The light symbolizes removal of darkness and ignorance."},
                {"step": 8, "title": "Aarti & Prasad", "description": "Perform aarti singing 'Om Jai Lakshmi Mata'. Distribute kheer and fruits as prasad."},
            ]),
            "deity_description": "Goddess Lakshmi is the divine consort of Lord Vishnu and the goddess of wealth, fortune, prosperity, and beauty. She embodies grace and abundance.",
            "significance": "Lakshmi Puja invites prosperity, removes financial obstacles, and blesses the household with abundance and well-being.",
        },
        "pooja_navagraha": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Set up 9 small platforms or spaces for each planet. Place 9 different colored cloths representing each graha."},
                {"step": 2, "title": "Kalash Sthapana", "description": "Place a main kalash in the center. Fill with water, turmeric, coins, and sacred leaves."},
                {"step": 3, "title": "Grain Arrangement", "description": "Place 9 different grains on each platform: wheat (Sun), rice (Moon), toor dal (Mars), moong (Mercury), chana (Jupiter), kidney beans (Venus), sesame (Saturn), urad (Rahu), horse gram (Ketu)."},
                {"step": 4, "title": "Individual Planet Puja", "description": "Worship each planet with its specific mantra, flower color, and offering. Start with Surya (Sun)."},
                {"step": 5, "title": "Havan (Fire Offering)", "description": "Light the sacred fire. Offer ghee and samidha (sacred wood) with each planet mantra 28 times."},
                {"step": 6, "title": "Abhishekam", "description": "Bathe each planet representation with sesame oil, milk, and water while chanting respective mantras."},
                {"step": 7, "title": "Naivedya", "description": "Offer different sweets and fruits to each planet. Light 9 ghee lamps."},
                {"step": 8, "title": "Aarti & Pradakshina", "description": "Perform aarti and walk around the setup 9 times clockwise. Seek blessings for planetary harmony."},
            ]),
            "deity_description": "The Navagrahas are the nine celestial bodies in Vedic astrology that influence human destiny: Surya, Chandra, Mangala, Budha, Brihaspati, Shukra, Shani, Rahu, and Ketu.",
            "significance": "Navagraha Shanti pacifies malefic planetary influences, restores cosmic balance, and removes doshas (flaws) from one's horoscope.",
        },
        "pooja_satyanarayan": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Clean the puja area. Prepare prasad (sheera/suji halwa) and gather all ingredients including banana, tulsi, and fruits."},
                {"step": 2, "title": "Kalash Sthapana", "description": "Set up the sacred kalash with water, mango leaves, coconut, and rice. Place Lord Vishnu's idol or image."},
                {"step": 3, "title": "Ganesh & Navagraha Puja", "description": "Begin with Ganesha puja and a brief Navagraha invocation for auspiciousness."},
                {"step": 4, "title": "Main Puja", "description": "Invoke Lord Satyanarayan with mantras. Perform abhishekam with panchamrit and offer tulsi leaves."},
                {"step": 5, "title": "Katha - Chapter 1 & 2", "description": "Read the first two chapters of Satyanarayan Katha describing the origin and glory of the vrat."},
                {"step": 6, "title": "Katha - Chapter 3 & 4", "description": "Continue with chapters describing devotees' stories and the consequences of forgetting God's grace."},
                {"step": 7, "title": "Katha - Chapter 5", "description": "Read the final chapter. Offer banana prasad and perform the concluding prayers."},
                {"step": 8, "title": "Aarti & Prasad Distribution", "description": "Perform aarti with camphor. Distribute sheera prasad to all present. Everyone should eat the prasad."},
            ]),
            "deity_description": "Lord Satyanarayan is a form of Lord Vishnu, the supreme preserver of the universe. He represents truth and is worshipped for fulfillment of desires and divine blessings.",
            "significance": "Satyanarayan Katha is performed for wish fulfillment, prosperity, and expressing gratitude. It is traditionally done on Purnima (full moon) days.",
        },
        "pooja_rudrabhishek": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Set up Shiva Linga or image. Prepare all 11 abhishekam items: milk, curd, honey, ghee, sugar water, coconut water, sandalwood paste, sacred ash, rose water, gangajal, panchamrit."},
                {"step": 2, "title": "Sankalpa", "description": "Take the sacred resolve stating the purpose of the puja. Light the ghee lamp and incense."},
                {"step": 3, "title": "Ganesh Puja", "description": "Begin with Lord Ganesha invocation for removal of obstacles in the puja."},
                {"step": 4, "title": "Rudra Abhishekam", "description": "Pour each item over the Shiva Linga one by one while chanting 'Om Namah Shivaya'. Start with water, then milk."},
                {"step": 5, "title": "Bilva Patra Offering", "description": "Offer 108 bilva (bael) leaves one at a time, each with 'Om Namah Shivaya'. Bilva is most dear to Shiva."},
                {"step": 6, "title": "Rudram Chanting", "description": "Chant Sri Rudram (Namakam and Chamakam) from Yajur Veda. This is the heart of the puja."},
                {"step": 7, "title": "Alankara & Naivedya", "description": "Decorate with sacred ash and flowers. Offer fruits, milk sweets, and coconut."},
                {"step": 8, "title": "Maha Aarti", "description": "Perform grand aarti with 5-wick ghee lamp. Chant 'Shiva Tandava Stotram' or 'Shiv Aarti'. Distribute prasad."},
            ]),
            "deity_description": "Lord Shiva, the Mahadeva, is the destroyer and transformer in the Hindu trinity. He represents the supreme consciousness and is known for his compassion toward devotees.",
            "significance": "Rudrabhishek is one of the most powerful Shiva pujas. It grants protection from negativity, spiritual transformation, and inner peace.",
        },
        "pooja_sundarkand": {
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Set up Hanuman ji's image or idol. Place Ramcharitmanas (Tulsidas) in front. Light a ghee lamp."},
                {"step": 2, "title": "Hanuman Invocation", "description": "Chant 'Om Hanumate Namah' 21 times. Apply sindoor to the idol. Offer jasmine oil and red flowers."},
                {"step": 3, "title": "Begin Sundarkand Path", "description": "Start reading from the Sundarkand section of Ramcharitmanas. Read Dohas 1-15 describing Hanuman's leap to Lanka."},
                {"step": 4, "title": "Hanuman in Lanka", "description": "Continue reading Dohas 16-30 about Hanuman's search for Sita in Lanka and his encounters."},
                {"step": 5, "title": "Meeting Sita", "description": "Read the sections describing Hanuman meeting Sita mata in Ashok Vatika and giving her Rama's ring."},
                {"step": 6, "title": "Lanka Dahan", "description": "Read about Hanuman setting Lanka on fire and his triumphant return to Lord Rama."},
                {"step": 7, "title": "Conclusion of Path", "description": "Complete the reading with the final dohas. Chant Hanuman Chalisa once."},
                {"step": 8, "title": "Aarti & Prasad", "description": "Perform Hanuman aarti. Offer betel leaves, fruits, and boondi as prasad. Distribute to all present."},
            ]),
            "deity_description": "Lord Hanuman is the greatest devotee of Lord Rama, embodying devotion, courage, strength, and selfless service. He is the son of Vayu (wind god).",
            "significance": "Sundarkand Path brings courage during difficult times, removes fear, protects the family, and strengthens faith in divine grace.",
        },
    }

    for pooja_id, data in steps_data.items():
        cur.execute("""
            UPDATE pooja_types
            SET steps = ?, deity_description = ?, significance = ?
            WHERE id = ?
        """, (data["steps"], data["deity_description"], data["significance"], pooja_id))

    # =========================================================================
    # Add 2 new pooja types: Hanuman Chalisa and Mahamrityunjaya
    # =========================================================================

    new_poojas = [
        {
            "id": "pooja_hanuman_chalisa",
            "name": "Hanuman Chalisa Path",
            "description": "Recite the powerful 40 verses in praise of Lord Hanuman for strength and protection",
            "deity": "Lord Hanuman",
            "duration_minutes": 60,
            "base_price": 1100,
            "icon_name": "flame.fill",
            "benefits": json.dumps(["Courage", "Strength", "Protection from evil", "Overcoming fear"]),
            "ingredients": json.dumps([
                "Sindoor", "Jasmine oil", "Red flowers", "Betel leaves (5)",
                "Boondi ladoo", "Ghee lamp"
            ]),
            "mantras": json.dumps([
                "Om Hanumate Namah",
                "Jai Hanuman gyan guna sagar",
                "Buddhiheen tanu jaanike sumirau pavan kumar"
            ]),
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Clean the puja space. Place Hanuman ji idol or image facing south. Light a ghee lamp and incense."},
                {"step": 2, "title": "Apply Sindoor", "description": "Apply sindoor to the idol. Offer jasmine oil. Sindoor is extremely dear to Hanuman ji."},
                {"step": 3, "title": "Opening Prayers", "description": "Chant 'Om Hanumate Namah' 11 times. Offer red flowers and betel leaves."},
                {"step": 4, "title": "Hanuman Chalisa - First Half", "description": "Recite the first 20 dohas of Hanuman Chalisa with devotion. Focus on each verse's meaning."},
                {"step": 5, "title": "Hanuman Chalisa - Second Half", "description": "Complete the remaining 20 dohas. End with the concluding doha praising Hanuman's grace."},
                {"step": 6, "title": "Repeat Recitation", "description": "For maximum benefit, recite the full Chalisa a total of 7 times. Count on a mala if available."},
                {"step": 7, "title": "Bajrang Baan (Optional)", "description": "For extra protection, recite Bajrang Baan once. This is especially powerful against negative energies."},
                {"step": 8, "title": "Aarti & Prasad", "description": "Perform Hanuman aarti. Offer boondi ladoo and fruits. Distribute prasad with devotion."},
            ]),
            "deity_description": "Lord Hanuman, also called Bajrangbali, is the mighty devotee of Lord Rama. He symbolizes unwavering devotion, immense strength, and selfless service.",
            "significance": "Hanuman Chalisa recitation bestows courage, removes fear, protects from evil influences, and strengthens one's resolve during difficult times. Tuesday and Saturday recitations are especially powerful.",
            "sort_order": 7,
        },
        {
            "id": "pooja_mahamrityunjaya",
            "name": "Mahamrityunjaya Japa",
            "description": "Chant the powerful death-conquering mantra for health, longevity, and overcoming illness",
            "deity": "Lord Shiva (Mrityunjaya)",
            "duration_minutes": 90,
            "base_price": 2100,
            "icon_name": "heart.circle.fill",
            "benefits": json.dumps(["Health restoration", "Longevity", "Protection from accidents", "Overcoming fear of death"]),
            "ingredients": json.dumps([
                "Bilva leaves (108)", "White flowers", "Milk (500ml)",
                "Honey", "Sacred ash (vibhuti)", "Rudraksha mala", "Ghee lamp"
            ]),
            "mantras": json.dumps([
                "Om Tryambakam Yajamahe Sugandhim Pushti-Vardhanam",
                "Urvarukamiva Bandhanan Mrityor Mukshiya Maamritat",
                "Om Namah Shivaya"
            ]),
            "steps": json.dumps([
                {"step": 1, "title": "Preparation", "description": "Set up Shiva Linga or image. Arrange 108 bilva leaves, white flowers, and a rudraksha mala. Light ghee lamp."},
                {"step": 2, "title": "Sankalpa", "description": "Take the sacred resolve stating the purpose: health, longevity, or healing for self or a loved one."},
                {"step": 3, "title": "Shiva Abhishekam", "description": "Pour milk over the Shiva Linga slowly while chanting 'Om Namah Shivaya' 11 times."},
                {"step": 4, "title": "Begin Japa - Round 1", "description": "Using a rudraksha mala, chant the Mahamrityunjaya mantra 108 times. Maintain steady rhythm and clear pronunciation."},
                {"step": 5, "title": "Bilva Leaf Offering", "description": "After each round of 108, offer a bilva leaf to the Shiva Linga with devotion."},
                {"step": 6, "title": "Continue Japa", "description": "Ideally complete 3 rounds (324 chants) or more. For serious illness, aim for 11 rounds over multiple sittings."},
                {"step": 7, "title": "Havan (Optional)", "description": "Offer ghee and black sesame seeds into sacred fire with each mantra chant for enhanced potency."},
                {"step": 8, "title": "Conclusion & Aarti", "description": "Apply sacred ash. Perform Shiva aarti. Distribute vibhuti and milk prasad. Pray for health and protection."},
            ]),
            "deity_description": "Lord Shiva in His Mrityunjaya (conqueror of death) form is the great healer and protector. This aspect of Shiva grants liberation from the cycle of death and rebirth.",
            "significance": "The Mahamrityunjaya Mantra is one of the most powerful mantras in the Vedas. It is chanted for healing the sick, preventing accidents, and overcoming the fear of death. It nourishes and rejuvenates the chanter.",
            "sort_order": 8,
        },
    ]

    for pooja in new_poojas:
        # Check if already exists
        cur.execute("SELECT id FROM pooja_types WHERE id = ?", (pooja["id"],))
        if cur.fetchone():
            continue

        cur.execute("""
            INSERT INTO pooja_types
            (id, name, description, deity, duration_minutes, base_price, icon_name,
             benefits, ingredients, mantras, steps, deity_description, significance,
             is_active, sort_order, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
        """, (
            pooja["id"], pooja["name"], pooja["description"], pooja["deity"],
            pooja["duration_minutes"], pooja["base_price"], pooja["icon_name"],
            pooja["benefits"], pooja["ingredients"], pooja["mantras"],
            pooja["steps"], pooja["deity_description"], pooja["significance"],
            pooja["sort_order"], now, now,
        ))


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS vedic_entries")
    cur.execute("DROP TABLE IF EXISTS user_temple_activity")
    # Cannot easily drop columns in SQLite; skip ALTER rollback
    # Delete seeded pooja types
    cur.execute("DELETE FROM pooja_types WHERE id IN ('pooja_hanuman_chalisa', 'pooja_mahamrityunjaya')")
    conn.commit()
