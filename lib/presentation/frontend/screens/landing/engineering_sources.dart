// Exact public excerpts. Tests compare these with Cortex API source.
const engineeringExcerpts = <({String path, String code})>[
  (
    path: "src/domain/models/pipeline.rs",
    code: r'''pub enum StageName {
    Accept,
    Gather,
    Assemble,
    Think,
    Answer,
    Save,
}''',
  ),
  (
    path: "src/dal/remote/event_journal.rs",
    code: r'''        let reply: redis::streams::StreamRangeReply = self
            .cache
            .execute(
                redis::cmd("XRANGE")
                    .arg(key.name())
                    .arg(format!("({after}-0"))
                    .arg("+")
                    .arg("COUNT")
                    .arg(self.batch),
            )
            .await?;''',
  ),
  (
    path: "src/domain/services/pipeline.rs",
    code: r'''    let previous = stages.last().expect("accepted");
    let start = Instant::now();
    reporter.start(StageName::Gather);
    let (mut files, mut memory, mut web) = tokio::join!(
        services.files(previous),
        services.memory(previous),
        services.web(previous)
    );''',
  ),
  (
    path: "src/domain/services/exchange_memory.rs",
    code: r'''        let id = self
            .hippocampus
            .create_exchange(
                scope,
                &Exchange {
                    session,
                    chat_title: assignment.title(),
                    input: assignment.input(),
                    output: assignment.output(),
                    topic: assignment.topic(),
                },
            )
            .await
            .map_err(|_| ())?;
        assignment.assign(&id).await.map_err(|_| ())?;''',
  ),
];
