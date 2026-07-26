import { StrictMode, useState, type FormEvent } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

const KRATOS_URL = import.meta.env.VITE_KRATOS_PUBLIC_URL ?? "http://localhost:4433";
const BRIDGE_URL = import.meta.env.VITE_BRIDGE_URL ?? "http://localhost:8081";

type Notice = { kind: "success" | "error"; message: string };
type KratosIdentity = { id: string; traits: { email: string; display_name?: string } };

function App() {
  const [notice, setNotice] = useState<Notice | null>(null);
  const [busy, setBusy] = useState(false);
  const [identityID, setIdentityID] = useState("");

  async function register(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice(null);
    const form = new FormData(event.currentTarget);
    const email = String(form.get("email") ?? "");
    const displayName = String(form.get("display_name") ?? "");
    const password = String(form.get("password") ?? "");

    try {
      const flowResponse = await fetch(`${KRATOS_URL}/self-service/registration/api`, {
        headers: { Accept: "application/json" },
      });
      const flow = await parseResponse<{ id: string }>(flowResponse);
      const registrationResponse = await fetch(
        `${KRATOS_URL}/self-service/registration?flow=${encodeURIComponent(flow.id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json", Accept: "application/json" },
          body: JSON.stringify({
            method: "password",
            password,
            traits: { email, display_name: displayName },
          }),
        },
      );
      const registration = await parseResponse<{ identity: KratosIdentity }>(registrationResponse);
      await postLifecycle("/v1/lifecycle/verification-requested", {
        identity_id: registration.identity.id,
        email,
        display_name: displayName,
      });
      setIdentityID(registration.identity.id);
      setNotice({
        kind: "success",
        message: "Account created. Check Mailpit for your verification code.",
      });
      event.currentTarget.reset();
    } catch (error) {
      setNotice({ kind: "error", message: errorMessage(error) });
    } finally {
      setBusy(false);
    }
  }

  async function verify(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice(null);
    const form = new FormData(event.currentTarget);
    const email = String(form.get("verify_email") ?? "");
    const code = String(form.get("code") ?? "");
    const identityID = String(form.get("identity_id") ?? "");

    try {
      const flowResponse = await fetch(`${KRATOS_URL}/self-service/verification/api`, {
        headers: { Accept: "application/json" },
      });
      const flow = await parseResponse<{ id: string }>(flowResponse);
      const verificationResponse = await fetch(
        `${KRATOS_URL}/self-service/verification?flow=${encodeURIComponent(flow.id)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json", Accept: "application/json" },
          body: JSON.stringify({ method: "code", code, email }),
        },
      );
      await parseResponse(verificationResponse);
      await postLifecycle("/v1/lifecycle/signup-completed", {
        identity_id: identityID,
        email,
        display_name: null,
      });
      setNotice({ kind: "success", message: "Email verified. Welcome aboard." });
      event.currentTarget.reset();
    } catch (error) {
      setNotice({ kind: "error", message: errorMessage(error) });
    } finally {
      setBusy(false);
    }
  }

  return (
    <main>
      <header>
        <span className="eyebrow">Mammoth data plane reference SaaS</span>
        <h1>Small signup.<br />Serious delivery.</h1>
        <p className="lede">
          Create an identity and watch a committed PostgreSQL event travel through
          Mammoth to an independent email sink.
        </p>
      </header>

      {notice ? <p className={`notice ${notice.kind}`} role="status">{notice.message}</p> : null}

      <section className="panels">
        <form onSubmit={register}>
          <span className="step">01</span>
          <h2>Create an account</h2>
          <label>Display name<input name="display_name" required minLength={1} maxLength={120} /></label>
          <label>Email<input name="email" type="email" required autoComplete="email" /></label>
          <label>Password<input name="password" type="password" required minLength={8} autoComplete="new-password" /></label>
          <button disabled={busy}>{busy ? "Working…" : "Register"}</button>
        </form>

        <form onSubmit={verify}>
          <span className="step">02</span>
          <h2>Complete verification</h2>
          <label>Identity ID<input name="identity_id" required value={identityID} onChange={(event) => setIdentityID(event.target.value)} /></label>
          <label>Email<input name="verify_email" type="email" required /></label>
          <label>Verification code<input name="code" required inputMode="numeric" /></label>
          <button disabled={busy}>{busy ? "Working…" : "Verify email"}</button>
        </form>
      </section>
      <footer>Mailpit inbox: <a href="http://localhost:8025">localhost:8025</a></footer>
    </main>
  );
}

async function postLifecycle(path: string, body: object) {
  const response = await fetch(`${BRIDGE_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(body),
  });
  return parseResponse(response);
}

async function parseResponse<T = unknown>(response: Response): Promise<T> {
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = payload as { error?: { message?: string }; message?: string };
    throw new Error(detail.error?.message ?? detail.message ?? `Request failed (${response.status})`);
  }
  return payload as T;
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Something went wrong";
}

createRoot(document.getElementById("root")!).render(
  <StrictMode><App /></StrictMode>,
);
