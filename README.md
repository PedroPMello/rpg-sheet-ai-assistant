# D&D 5e AI Companion — Gerenciador de Fichas com Inteligência Artificial

> **Status do Projeto:** Em desenvolvimento ativo (*Work in Progress*)

Aplicativo mobile multiplataforma desenvolvido em **Flutter** para criação, gerenciamento e consulta de fichas de personagens de **Dungeons & Dragons (5ª Edição)**, integrando dados oficiais de regras via API pública e um assistente interativo alimentado pela **Google Gemini API**.

---

## Sobre o Projeto

Criar fichas de RPG de mesa e consultar regras durante uma sessão exige lidar com dezenas de atributos, magias, classes e modificadores. Este projeto resolve esse atrito unindo uma interface mobile responsiva a um **assistente baseado em LLM (Gemini)** capaz de auxiliar jogadores na montagem de personagens, sugestão de builds e esclarecimento rápido de regras do sistema D&D 5e.

### Funcionalidades Planejadas & Em Implementação
- [x] Estruturação inicial da arquitetura do projeto em Flutter/Dart.
- [x] Integração com API externa de regras e recursos de D&D 5e (classes, raças, magias e equipamentos).
- [ ] Autenticação de usuários e persistência em nuvem via **Firebase (Auth & Cloud Firestore)**.
- [ ] **Assistente de IA (Google Gemini API):** Chat contextual para auxílio na criação de fichas, cálculo de atributos e consulta de regras em linguagem natural.
- [ ] CRUD completo de fichas de personagens com atualização dinâmica de modificadores e inventário.

---

## Stack Tecnológica

- **Mobile / Front-end:** Flutter & Dart
- **Inteligência Artificial:** Google Gemini API (Engenharia de Prompt e geração estruturada)
- **Backend & Persistência:** Firebase Authentication & Cloud Firestore
- **Integrações:** D&D 5e REST API

---

## Como Executar Localmente

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado.
- Uma chave de API válida do [Google AI Studio (Gemini API)](https://aistudio.google.com/).
- Projeto configurado no [Firebase Console](https://console.firebase.google.com/).

### Passos para Instalação

```bash
# 1. Clone o repositório
git clone [https://github.com/PedroPMello/dnd-ai-companion.git](https://github.com/PedroPMello/dnd-ai-companion.git)

# 2. Acesse a pasta do projeto
cd dnd-ai-companion

# 3. Instale as dependências
flutter pub get

# 4. Configure as variáveis de ambiente (adicione sua GEMINI_API_KEY)
cp .env.example .env

# 5. Execute o aplicativo
flutter run
```

---

## Autor

**Pedro Pizzolato Mello**  
- GitHub: [@PedroPMello](https://github.com/PedroPMello)
- LinkedIn: [Pedro Pizzolato Mello](https://www.linkedin.com/in/pedro-pizzolato-mello)
