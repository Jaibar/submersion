#!/usr/bin/env python3
"""Tests for UDDF test data generator helper functions."""

import math
import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_uddf_test_data import (
    PerlinNoise,
    DiverPersonality,
    breathing_oscillation,
    generate_micro_events,
    apply_micro_event,
)


class TestPerlinNoise(unittest.TestCase):
    """Test the 1D Perlin noise implementation."""

    def test_output_range(self):
        """Noise output should be in approximately [-1, 1] range."""
        noise = PerlinNoise(seed=42)
        values = [noise.noise(t * 0.1) for t in range(1000)]
        self.assertTrue(
            all(-1.5 <= v <= 1.5 for v in values),
            f"Values out of range: min={min(values)}, max={max(values)}",
        )

    def test_smoothness(self):
        """Adjacent samples should not have large jumps."""
        noise = PerlinNoise(seed=42)
        step = 0.01
        for i in range(999):
            t1 = i * step
            t2 = (i + 1) * step
            diff = abs(noise.noise(t2) - noise.noise(t1))
            self.assertLess(diff, 0.2, f"Jump too large at t={t1}: {diff}")

    def test_deterministic(self):
        """Same seed and input should produce same output."""
        noise1 = PerlinNoise(seed=42)
        noise2 = PerlinNoise(seed=42)
        for t in [0.0, 1.5, 10.7, 100.3]:
            self.assertEqual(noise1.noise(t), noise2.noise(t))

    def test_different_seeds_differ(self):
        """Different seeds should produce different outputs."""
        noise1 = PerlinNoise(seed=42)
        noise2 = PerlinNoise(seed=99)
        differences = sum(
            1
            for t in [0.5, 1.5, 2.5, 3.5, 4.5]
            if noise1.noise(t) != noise2.noise(t)
        )
        self.assertGreater(differences, 0)

    def test_non_periodic_over_dive_length(self):
        """Should not repeat within a typical dive duration."""
        noise = PerlinNoise(seed=42)
        segment1 = [noise.noise(t * 0.02) for t in range(0, 300)]
        segment2 = [noise.noise(t * 0.02) for t in range(300, 600)]
        self.assertNotEqual(segment1, segment2)


class TestDiverPersonality(unittest.TestCase):
    """Test diver personality generation."""

    def test_fields_in_range(self):
        """All personality fields should be in [0, 1] range."""
        import random as rng

        rng.seed(42)
        for _ in range(100):
            p = DiverPersonality.generate(dive_number=50, total_dives=500)
            self.assertTrue(0 <= p.skill_level <= 1)
            self.assertTrue(0 <= p.activity_level <= 1)

    def test_skill_progression(self):
        """Later dives should tend toward higher skill."""
        import random as rng

        rng.seed(42)
        early = [DiverPersonality.generate(i, 500).skill_level for i in range(1, 20)]
        late = [DiverPersonality.generate(i, 500).skill_level for i in range(480, 500)]
        self.assertGreater(sum(late) / len(late), sum(early) / len(early))

    def test_descent_rate_varies_with_skill(self):
        """Experienced divers should have faster descent rates."""
        novice = DiverPersonality(skill_level=0.2, activity_level=0.5)
        expert = DiverPersonality(skill_level=0.9, activity_level=0.5)
        self.assertLess(novice.descent_rate_range[0], expert.descent_rate_range[0])


class TestBreathingOscillation(unittest.TestCase):
    """Test breathing oscillation function."""

    def test_amplitude_range(self):
        """Breathing oscillation should be within expected amplitude."""
        for skill in [0.2, 0.5, 0.9]:
            values = [breathing_oscillation(t, skill) for t in range(0, 600, 5)]
            max_amp = max(abs(v) for v in values)
            self.assertLess(
                max_amp, 0.5, f"Breathing amplitude too large for skill {skill}"
            )

    def test_experienced_smaller_amplitude(self):
        """Higher skill should produce smaller breathing oscillation."""
        novice = [abs(breathing_oscillation(t, 0.2)) for t in range(0, 600, 5)]
        expert = [abs(breathing_oscillation(t, 0.9)) for t in range(0, 600, 5)]
        self.assertGreater(max(novice), max(expert))


class TestMicroEvents(unittest.TestCase):
    """Test micro-event generation and application."""

    def test_event_count_in_range(self):
        """Should generate reasonable number of events."""
        import random as rng

        rng.seed(42)
        events = generate_micro_events(60, 600, 20.0, 0.5, 25.0)
        self.assertTrue(1 <= len(events) <= 8)

    def test_events_within_time_range(self):
        """All events should start within the level's time range."""
        import random as rng

        rng.seed(42)
        events = generate_micro_events(100, 500, 20.0, 0.8, 25.0)
        for event in events:
            self.assertGreaterEqual(event["start_time"], 100)
            self.assertLessEqual(event["start_time"], 600)

    def test_event_depth_offset_reasonable(self):
        """Event depth offsets should not exceed bounds."""
        import random as rng

        rng.seed(42)
        for _ in range(50):
            events = generate_micro_events(0, 600, 20.0, 0.9, 25.0)
            for event in events:
                self.assertLessEqual(abs(event["depth_offset"]), 5.0)

    def test_apply_returns_zero_outside_event(self):
        """apply_micro_event should return 0 outside event window."""
        event = {
            "start_time": 100,
            "duration": 30,
            "depth_offset": -2.0,
            "event_type": "look_below",
        }
        self.assertAlmostEqual(apply_micro_event(event, 50), 0.0)
        self.assertAlmostEqual(apply_micro_event(event, 200), 0.0)

    def test_apply_returns_nonzero_during_event(self):
        """apply_micro_event should return depth offset during event."""
        event = {
            "start_time": 100,
            "duration": 30,
            "depth_offset": -2.0,
            "event_type": "look_below",
        }
        offset = apply_micro_event(event, 115)
        self.assertNotAlmostEqual(offset, 0.0)


if __name__ == "__main__":
    unittest.main()
