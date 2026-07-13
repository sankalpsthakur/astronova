def test_public_compliance_pages_are_available(client):
    expected_titles = {
        "/terms": "Terms of Service",
        "/privacy": "Privacy Policy",
        "/support": "Support",
    }

    for path, title in expected_titles.items():
        response = client.get(path)

        assert response.status_code == 200
        assert response.mimetype == "text/html"
        assert title in response.get_data(as_text=True)


def test_public_compliance_pages_use_current_support_copy(client):
    terms = client.get("/terms").get_data(as_text=True)
    privacy = client.get("/privacy").get_data(as_text=True)
    support = client.get("/support").get_data(as_text=True)

    assert "Last updated: May 2026" in terms
    assert "Last updated: May 2026" in privacy
    assert "mailto:admin@100xai.engineering" in terms
    assert "mailto:admin@100xai.engineering" in privacy
    assert "mailto:admin@100xai.engineering" in support
    assert "latest available Astronova build" in support
    assert "leave us a review on the App Store" not in support
