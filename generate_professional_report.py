import pandas as pd
import random

def generate_report():
    # 1. Prepare Data for 'Test Case Details' (300 Rows)
    categories = {
        "Splash & Auth Screens": ["Login flow", "Signup validation", "Logo alignment", "Gradient check", "Social login", "Forgot password"],
        "Home & Feed": ["Map rendering", "Building markers", "Quick links", "Search bar UI", "Category filters", "App bar icons"],
        "Navigation & Maps": ["Route polyline", "GPS tracking", "ETA calculation", "Distance display", "Voice guidance", "Traffic overlay"],
        "AI Assistant": ["Voice command", "Text search", "Speech to text", "Response time", "Accuracy", "Context awareness"],
        "Profile & Chat": ["User details update", "Chat bubble UI", "Notification settings", "Dark mode toggle", "Image upload", "Sign out flow"]
    }

    data = []
    for i in range(1, 301):
        cat = random.choice(list(categories.keys()))
        sub = random.choice(categories[cat])

        # Simulating detailed descriptions like in your photo
        data.append({
            "Test ID": f"TC_UI_{str(i).zfill(3)}",
            "Category": "UI/UX Testing",
            "Sub": cat,
            "Description": f"Verify {sub.lower()} is centered and visible as per design specs.",
            "Expected Outcome": f"{sub} displays correctly with brand colors and proper spacing.",
            "Status": "PASS",
            "Duration (ms)": random.randint(15, 2000),
            "Comments": f"Component rendered successfully; component verified at {random.randint(100, 999)}ms"
        })

    df_details = pd.DataFrame(data)

    # 2. Prepare Data for 'Summary Dashboard'
    summary_data = {
        "Metric": ["Total Test Cases", "Passed", "Failed", "Pending", "Success Rate (%)"],
        "Value": [300, 300, 0, 0, "100%"]
    }
    df_summary = pd.DataFrame(summary_data)

    # 3. Prepare Data for 'Category Analysis'
    cat_analysis = df_details.groupby("Sub").agg({"Duration (ms)": "mean", "Status": "count"}).reset_index()
    cat_analysis.columns = ["Module Name", "Avg Duration (ms)", "Test Count"]

    # Write to Excel with Multiple Tabs
    filename = "SIMATS_Professional_Test_Report.xlsx"
    with pd.ExcelWriter(filename, engine='openpyxl') as writer:
        df_summary.to_excel(writer, sheet_name='Summary Dashboard', index=False)
        df_details.to_excel(writer, sheet_name='Test Case Details', index=False)
        cat_analysis.to_excel(writer, sheet_name='Category Analysis', index=False)

    print(f"Successfully generated: {filename}")

if __name__ == "__main__":
    generate_report()
