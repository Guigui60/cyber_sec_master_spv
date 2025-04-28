from flask import Flask, render_template_string
import subprocess

app = Flask(__name__)

TEMPLATE = """
<!DOCTYPE html>
<html lang=\"fr\">
<head>
    <meta charset=\"UTF-8\">
    <title>Fail2Ban - IP Bannies</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px; }
        h1 { color: #333; }
        ul { list-style: none; padding: 0; }
        li { background: white; margin: 5px 0; padding: 10px; border-radius: 8px; }
    </style>
</head>
<body>
    <h1>📋 Liste des IP bannies</h1>
    <ul>
        {% for ip in banned_ips %}
        <li>{{ ip }}</li>
        {% endfor %}
    </ul>
</body>
</html>
"""

def get_banned_ips():
    try:
        output = subprocess.check_output(["which", "fail2ban-client"], text=True).strip()
        fail2ban_client = output
        
        
        output = subprocess.check_output([
            fail2ban_client, 
            "--socket", "/var/run/fail2ban/fail2ban.sock",
            "status", 
            "nginx-http-auth"
        ], text=True)
        
        for line in output.splitlines():
            if "Banned IP list" in line:
                ip_part = line.split(":")[1].strip()
                return ip_part.split() if ip_part else []
        return []
    except subprocess.CalledProcessError as e:
        print(f"Erreur: {e}")
        try:
            jails = subprocess.check_output([
                fail2ban_client,
                "--socket", "/var/run/fail2ban/fail2ban.sock",
                "status"
            ], text=True)
            print(f"Jails disponibles: {jails}")
        except Exception as inner_e:
            print(f"Erreur lors de la récupération des jails: {inner_e}")
        return []
    except Exception as e:
        print(f"Exception générale: {e}")
        return []

@app.route("/")
def home():
    banned_ips = get_banned_ips()
    return render_template_string(TEMPLATE, banned_ips=banned_ips)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
