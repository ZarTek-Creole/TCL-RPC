# Namespace RPCServer
# RPC for eggdrop. Botnets are cool, but being able to tclute commands from one bot to another is better
# Ce script est sous licence GNU GPL v3
# http://www.gnu.org/licenses/gpl-3.0.html
# Auteur : Zartek-Creole (Zartek)
# Site web : https://github.com/ZarTek-Creole
# Bogues : https://github.com/ZarTek-Creole/TCL-RPC/issues

if { [namespace exists ::RPCServer] } { ::RPCServer::deInitialisation }

# Création du namespace
namespace eval ::RPCServer {
  variable SOCKET_PIPE          [list];
}

# procedure de désinitialisation
proc ::RPCServer::deInitialisation {args} {
  variable SOCKET_PIPE
  # Désallocation des ressources
  # Suppression des bindings
  # Suppression des timers
  # Suppression des utimers
  # Suppression du namespace
  putlog "Désallocation des ressources de ::RPCServer"
  catch {close ${SOCKET_PIPE}}

  foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range ::RPCServer 2 end]]*] " \{?(::)?::RPCServer"] {
    unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4]
  }
  foreach runningTimer [timers] {
    if { [::tcl::string::match "*::RPCServer::*" [lindex ${runningTimer} 1]] } { killtimer [lindex ${runningTimer} 2] }
  }
  foreach runningUTimer [utimers] {
    if { [::tcl::string::match "*::RPCServer::*" [lindex ${runningUTimer} 1]] } { killutimer [lindex ${runningUTimer} 2] }
  }
  foreach childNameSpace [namespace children ::RPCServer] {
    namespace delete ${childNameSpace}
  }
  namespace delete ::RPCServer
}
proc ::RPCServer::initialisation {args} {
  variable SOCKET_PIPE
  variable RPC
  set scriptPath                [file dirname [file normalize [info script]]]
  try {
    # Chargement du fichier de configuration
    source ${scriptPath}/rpc-server.cfg
  } on error {result options} {
    # Erreur de chargement du fichier de configuration
    ::RPCServer::sentLog "Impossible de charger le fichier de configuration : ${errorMessage}"
    return -options ${options} ${result}
  }

  # Démarrage du serveur RPC sur le port défini dans le fichier de configuration
  if {[catch {set SOCKET_PIPE [socket -server ::RPCServer::handleConnect ${RPC(port)}]} catchResult]} {
    ::RPCServer::sentLog "Impossible de démarrer le serveur RPC sur le port ${RPC(port)} : ${catchResult}"
    return 1
  }
  ::RPCServer::sentLog "Serveur RPC démarré sur le port ${RPC(port)}"
  return 0
}
# Gestions du socket serveur RPC
proc ::RPCServer::handleConnect {socketPipe clientAddress clientPort} {
  ::RPCServer::sentLog "Connexion entrante de ${clientAddress}:${clientPort}"
  # Gestion des connexions entrantes
  flush ${socketPipe}
  # Configuration du socket
  fconfigure ${socketPipe} -blocking 0 -buffering line -translation auto
  # Ecoute en lecture sur le socket et envois des données dans ::RPCServer::handleRead
  fileevent ${socketPipe} readable [list ::RPCServer::handleRead ${socketPipe}]
}
# Lecture des données reçues sur le socket serveur RPC
proc ::RPCServer::handleRead {socketPipe} {
  variable RPC
  if { [gets ${socketPipe} bufferLine] < 0 } {
    close ${socketPipe}
    return 1
  }

  # Découpage de la ligne reçue
  set ClientPassword          [lindex ${bufferLine} 0];
  set ClientCommand           [lindex ${bufferLine} 1];
  set ClientArgs              [lrange ${bufferLine} 2 end];

  # Vérification du mot de passe
  if { ![string match ${ClientPassword} ${RPC(password)}] } {
    puts ${socketPipe} "ERROR: Invalid password"
    close ${socketPipe}
    return 1
  }

  # Vérification des arguments
  if { ${ClientArgs} == "" } {
    puts ${socketPipe} "ERROR: Invalid arguments"
    close ${socketPipe}
    return 1
  }

  if { [string match -nocase "tcl" ${ClientCommand}] } {
    ::RPCServer::sentLog "Execution TCL de la commande ${ClientArgs}"
    puts ${socketPipe} [::RPCServer::tcl ${ClientArgs}];
    close ${socketPipe}
    return 0
  } elseif { [string match -nocase "call" ${ClientCommand}] } {
    ::RPCServer::sentLog "Execution de la fonction ${ClientArgs}"
    puts ${socketPipe} [::RPCServer::call ${ClientArgs}];
    close ${socketPipe}
    return 0
  } else {
    ::RPCServer::sentLog "Commande inconnue ${ClientCommand}"
    puts ${socketPipe} "ERROR: Invalid command";
    close ${socketPipe}
    return 1
  }
  close ${socketPipe}
}


proc ::RPCServer::tcl { arg } {
  set tryMessage [catch {eval {*}${arg}} returnMessage];
  if { ${tryMessage} == 0 } {
    if { ${errorMessage} == "" } {
      set returnMessage "OK"
    }
  } elseif { ${tryMessage} == 1 } {
    set returnMessage "ERROR: Invalid command ${returnMessage}"
  } elseif { ${tryMessage} == 2 } {
    set returnMessage [concat ${returnMessage}]
  } else {
    set returnMessage "${tryMessage}: ${returnMessage}"
  }
  return ${returnMessage};
}

proc ::RPCServer::call { arg } {
  set procName                  [lindex ${arg} 0]
  set args                      [lrange ${arg} 1 end]
  putlog "Call ${procName} ${args}"
  if { [info commands [set procName]] != "" } {
    putlog "ok ${procName} exist"
    return [eval ${procName} ${args}]
  } else {
    putlog "error ${procName} don't exist"
    return "ERROR: can't call ${procName}, don't exist"
  }
}

proc ::RPCServer::sentLog { arg } {
  variable RPC
  if { ${RPC(debug)} == 1 } {
    putlog "[namespace current] > RPCServer: ${arg}"
  }
}
# Démarrage du serveur RPC
::RPCServer::initialisation

proc ::MonTestcall {args} {
  return "Call OK"
}