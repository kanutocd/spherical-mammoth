import { StrictMode, useState, type FormEvent } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

const KRATOS_URL = import.meta.env.VITE_KRATOS_PUBLIC_URL ?? "http://localhost:4433";
const BRIDGE_URL = import.meta.env.VITE_BRIDGE_URL ?? "http://localhost:8081";

type Notice = { kind: "success" | "error"; message: string };
type FlowKind = "registration" | "verification";
type KratosMessage = { id: number; text: string; type: "error" | "info" | "success" };
type KratosNode = {
  attributes: {
    name?: string;
    type?: string;
    value?: unknown;
    disabled?: boolean;
    node_type: string;
  };
  messages: KratosMessage[];
};
type KratosFlow = {
  id: string;
  type: "browser";
  state?: string;
  ui: {
    action: string;
    method: string;
    nodes: KratosNode[];
    messages?: KratosMessage[];
  };
};
type KratosIdentity = {
  id: string;
  traits: { email: string; display_name?: string };
};
type RegistrationResult = {
  identity: KratosIdentity;
  continue_with?: Array<{ action: string; flow?: { id: string; url: string } }>;
};

class FlowError extends Error {
  constructor(public flow: KratosFlow) {
    super(flowMessages(flow)[0] ?? "Please correct the highlighted fields.");
  }
}

function App() {
  const [notice, setNotice] = useState<Notice | null>(null);
  const [busy, setBusy] = useState(false);
  const [registrationFlow, setRegistrationFlow] = useState<KratosFlow | null>(null);
  const [verificationFlow, setVerificationFlow] = useState<KratosFlow | null>(null);
  const [identity, setIdentity] = useState<KratosIdentity | null>(null);

  async function register(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice(null);
    const form = new FormData(event.currentTarget);
    const email = String(form.get("email") ?? "");
    const displayName = String(form.get("display_name") ?? "");
    const password = String(form.get("password") ?? "");

    try {
      const flow = registrationFlow ?? await createBrowserFlow("registration");
      setRegistrationFlow(flow);
      const registration = await submitBrowserFlow<RegistrationResult>(flow, {
        csrf_token: csrfToken(flow),
        method: "password",
        password,
        traits: { email, display_name: displayName },
      });

      setIdentity(registration.identity);
      setRegistrationFlow(null);
      await postLifecycle("/v1/lifecycle/verification-requested", {
        identity_id: registration.identity.id,
        email,
        display_name: displayName,
      });

      const continuation = registration.continue_with?.find(
        ({ action, flow: continuationFlow }) =>
          action === "show_verification_ui" && Boolean(continuationFlow?.id),
      );
      const nextVerificationFlow = continuation?.flow
        ? await getBrowserFlow("verification", continuation.flow.id)
        : await startCodeVerification(email);
      setVerificationFlow(nextVerificationFlow);
      setNotice({
        kind: "success",
        message: "Account created. Kratos sent a verification code to Mailpit.",
      });
      event.currentTarget.reset();
    } catch (error) {
      if (error instanceof FlowError) {
        setRegistrationFlow(error.flow);
      }
      setNotice({ kind: "error", message: errorMessage(error) });
    } finally {
      setBusy(false);
    }
  }

  async function verify(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!verificationFlow || !identity) {
      setNotice({ kind: "error", message: "Register an account before entering a verification code." });
      return;
    }

    setBusy(true);
    setNotice(null);
    const form = new FormData(event.currentTarget);
    const code = String(form.get("code") ?? "");

    try {
      const completedFlow = await submitBrowserFlow<KratosFlow>(verificationFlow, {
        csrf_token: csrfToken(verificationFlow),
        method: "code",
        code,
      });
      setVerificationFlow(completedFlow);
      if (completedFlow.state !== "passed_challenge") {
        throw new FlowError(completedFlow);
      }

      await postLifecycle("/v1/lifecycle/signup-completed", {
        identity_id: identity.id,
        email: identity.traits.email,
        display_name: identity.traits.display_name ?? null,
      });
      setNotice({ kind: "success", message: "Email verified. Welcome aboard." });
      event.currentTarget.reset();
    } catch (error) {
      if (error instanceof FlowError) {
        setVerificationFlow(error.flow);
      }
      setNotice({ kind: "error", message: errorMessage(error) });
    } finally {
      setBusy(false);
    }
  }

  async function resendCode() {
    if (!identity) {
      return;
    }
    setBusy(true);
    setNotice(null);
    try {
      const flow = await startCodeVerification(identity.traits.email);
      setVerificationFlow(flow);
      setNotice({ kind: "success", message: "Kratos sent a new verification code." });
    } catch (error) {
      if (error instanceof FlowError) {
        setVerificationFlow(error.flow);
      }
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
        <form onSubmit={register} noValidate>
          <span className="step">01</span>
          <h2>Create an account</h2>
          <FlowMessages flow={registrationFlow} />
          <Field label="Display name" name="display_name" required minLength={1} maxLength={120} flow={registrationFlow} />
          <Field label="Email" name="email" type="email" required autoComplete="email" flow={registrationFlow} />
          <Field label="Password" name="password" type="password" required minLength={8} autoComplete="new-password" flow={registrationFlow} />
          <button disabled={busy}>{busy ? "Working…" : "Register with Kratos"}</button>
        </form>

        <form onSubmit={verify} noValidate>
          <span className="step">02</span>
          <h2>Complete verification</h2>
          <FlowMessages flow={verificationFlow} />
          <p className="flow-context">
            {identity
              ? <>Code sent to <strong>{identity.traits.email}</strong>.</>
              : "Registration starts the browser verification flow."}
          </p>
          <Field label="Verification code" name="code" required inputMode="numeric" autoComplete="one-time-code" flow={verificationFlow} />
          <button disabled={busy || !verificationFlow}>{busy ? "Working…" : "Verify email"}</button>
          <button className="secondary" type="button" disabled={busy || !identity} onClick={resendCode}>Resend code</button>
        </form>
      </section>
      <footer>Mailpit inbox: <a href="http://localhost:8025">localhost:8025</a></footer>
    </main>
  );
}

type FieldProps = React.InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  flow: KratosFlow | null;
};

function Field({ label, flow, name, ...props }: FieldProps) {
  const messages = nodeMessages(flow, String(name));
  const errorID = messages.length > 0 ? `${name}-error` : undefined;
  return (
    <label>
      {label}
      <input name={name} aria-invalid={messages.length > 0} aria-describedby={errorID} {...props} />
      {messages.length > 0
        ? <span className="field-error" id={errorID}>{messages.join(" ")}</span>
        : null}
    </label>
  );
}

function FlowMessages({ flow }: { flow: KratosFlow | null }) {
  const messages = flow?.ui.messages?.map((message) => message.text) ?? [];
  return messages.length > 0 ? <p className="flow-message">{messages.join(" ")}</p> : null;
}

async function startCodeVerification(email: string) {
  const flow = await createBrowserFlow("verification");
  return submitBrowserFlow<KratosFlow>(flow, {
    csrf_token: csrfToken(flow),
    method: "code",
    email,
  });
}

async function createBrowserFlow(kind: FlowKind): Promise<KratosFlow> {
  const response = await fetch(`${KRATOS_URL}/self-service/${kind}/browser`, {
    headers: { Accept: "application/json" },
    credentials: "include",
  });
  return parseKratosResponse<KratosFlow>(response);
}

async function getBrowserFlow(kind: FlowKind, id: string): Promise<KratosFlow> {
  const query = new URLSearchParams({ id });
  const response = await fetch(`${KRATOS_URL}/self-service/${kind}/flows?${query}`, {
    headers: { Accept: "application/json" },
    credentials: "include",
  });
  return parseKratosResponse<KratosFlow>(response);
}

async function submitBrowserFlow<T>(flow: KratosFlow, body: object): Promise<T> {
  const response = await fetch(flow.ui.action, {
    method: flow.ui.method,
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    credentials: "include",
    body: JSON.stringify(body),
  });
  return parseKratosResponse<T>(response);
}

async function parseKratosResponse<T>(response: Response): Promise<T> {
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (isKratosFlow(payload)) {
      throw new FlowError(payload);
    }
    const detail = payload as { error?: { reason?: string; message?: string }; message?: string };
    throw new Error(
      detail.error?.reason ?? detail.error?.message ?? detail.message ?? `Kratos request failed (${response.status})`,
    );
  }
  return payload as T;
}

function csrfToken(flow: KratosFlow) {
  const node = flow.ui.nodes.find(
    ({ attributes }) => attributes.node_type === "input" && attributes.name === "csrf_token",
  );
  if (typeof node?.attributes.value !== "string" || !node.attributes.value) {
    throw new Error("Kratos browser flow did not provide a CSRF token.");
  }
  return node.attributes.value;
}

function nodeMessages(flow: KratosFlow | null, name: string) {
  return flow?.ui.nodes
    .filter((node) => node.attributes.name === name)
    .flatMap((node) => node.messages.map((message) => message.text)) ?? [];
}

function flowMessages(flow: KratosFlow) {
  return [
    ...(flow.ui.messages ?? []).map((message) => message.text),
    ...flow.ui.nodes.flatMap((node) => node.messages.map((message) => message.text)),
  ];
}

function isKratosFlow(value: unknown): value is KratosFlow {
  if (!value || typeof value !== "object") {
    return false;
  }
  const candidate = value as Partial<KratosFlow>;
  return typeof candidate.id === "string" && typeof candidate.ui?.action === "string";
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
