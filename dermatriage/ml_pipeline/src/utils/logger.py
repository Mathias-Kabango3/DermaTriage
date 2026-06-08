"""Logging and Weights & Biases setup for the DermaTriage ML pipeline."""

import logging

_LOG_FORMAT = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


def get_logger(name):
    """Configure root logging and return a named logger.

    Args:
        name: Logger name, typically ``__name__`` of the caller.

    Returns:
        logging.Logger: A configured logger.
    """
    logging.basicConfig(
        level=logging.INFO,
        format=_LOG_FORMAT,
        datefmt=_DATE_FORMAT,
    )
    return logging.getLogger(name)


def init_wandb(cfg, job_type):
    """Initialise a Weights & Biases run from the config's ``wandb`` section.

    Args:
        cfg: Full pipeline config dict (must contain a ``wandb`` key).
        job_type: Short label for the run's job type (e.g. ``"train_teacher"``).

    Returns:
        The active ``wandb`` run.
    """
    import wandb  # imported lazily so the package works without wandb installed

    wandb_cfg = cfg["wandb"]
    return wandb.init(
        entity=wandb_cfg["entity"],
        project=wandb_cfg["project"],
        job_type=job_type,
        config=cfg,
    )
